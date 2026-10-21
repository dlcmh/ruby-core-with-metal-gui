#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

# The Ruby-side core. It owns the lifecycle of the native rendering service;
# it does not render anything itself.
module RubyMetalCore
  ROOT = File.expand_path(__dir__)
  SOURCE = File.join(ROOT, "metal", "service.swift")
  BUILD_DIR = File.join(ROOT, "build")
  BINARY = File.join(BUILD_DIR, "metal-service")
  DEFAULT_SPEED = 0.9 # radians per second

  module_function

  def run(argv)
    speed = parse_args(argv)
    compile_service

    puts "[core] launching Metal rendering service at #{speed} rad/s"
    pid = Process.spawn(BINARY, "--speed", speed.to_s)

    %w[INT TERM].each do |signal|
      trap(signal) do
        Process.kill(signal, pid)
      rescue Errno::ESRCH
        # The service already exited.
      end
    end

    _, status = Process.wait2(pid)
    exit(status.exitstatus || (128 + status.termsig.to_i))
  end

  def compile_service
    return if File.exist?(BINARY) && File.mtime(BINARY) >= File.mtime(SOURCE)

    FileUtils.mkdir_p(BUILD_DIR)
    puts "[core] compiling native service"

    command = [
      "swiftc", "-O", SOURCE, "-o", BINARY,
      "-framework", "AppKit",
      "-framework", "Metal",
      "-framework", "MetalKit",
      "-framework", "QuartzCore"
    ]

    abort "[core] compilation failed" unless system(*command)
  end

  def parse_args(argv)
    if argv.include?("--help") || argv.include?("-h")
      puts "Usage: ruby core.rb [--speed RADIANS_PER_SECOND]"
      exit
    end

    index = argv.index("--speed")
    return DEFAULT_SPEED unless index

    value = argv[index + 1]
    speed = begin
      Float(value)
    rescue ArgumentError, TypeError
      nil
    end

    unless speed&.finite?
      abort "usage: ruby core.rb [--speed RADIANS_PER_SECOND]"
    end

    speed
  end
end

RubyMetalCore.run(ARGV)
