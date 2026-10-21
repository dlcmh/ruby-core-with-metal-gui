#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "rbconfig"

# Smoke checks for the Ruby supervisor. They exercise only paths that exit before
# compile_service is called, so the suite never builds or opens a window.
module CheckCore
  ROOT = File.expand_path("..", __dir__)
  RUBY = RbConfig.ruby
  USAGE = "Usage: ruby core.rb [--speed RADIANS_PER_SECOND]"

  CASES = [
    {
      args: ["--help"],
      status: 0,
      stdout: /\A#{Regexp.escape(USAGE)}\n\z/,
      stderr: /\A\z/
    },
    {
      args: ["-h"],
      status: 0,
      stdout: /\A#{Regexp.escape(USAGE)}\n\z/,
      stderr: /\A\z/
    },
    {
      args: ["--speed", "not-a-number"],
      status: :nonzero,
      stdout: /\A\z/,
      stderr: /usage: ruby core\.rb/
    },
    {
      args: ["--speed"],
      status: :nonzero,
      stdout: /\A\z/,
      stderr: /usage: ruby core\.rb/
    },
    {
      args: ["--speed", "NaN"],
      status: :nonzero,
      stdout: /\A\z/,
      stderr: /usage: ruby core\.rb/
    },
    {
      args: ["--speed", "Infinity"],
      status: :nonzero,
      stdout: /\A\z/,
      stderr: /usage: ruby core\.rb/
    }
  ].freeze

  module_function

  def run
    checks = 0
    failures = []

    CASES.each do |expectation|
      args = expectation[:args]
      stdout, stderr, status = Open3.capture3(RUBY, "core.rb", *args, chdir: ROOT)
      label = "ruby core.rb #{args.join(' ')}"

      checks += 1
      failures << "#{label}: expected #{expectation[:status]}, got #{status.exitstatus.inspect}" unless status_ok?(status, expectation[:status])

      checks += 1
      failures << "#{label}: stdout #{stdout.inspect} does not match #{expectation[:stdout].inspect}" unless expectation[:stdout].match?(stdout)

      checks += 1
      failures << "#{label}: stderr #{stderr.inspect} does not match #{expectation[:stderr].inspect}" unless expectation[:stderr].match?(stderr)
    end

    failures.each { |failure| puts "FAIL: #{failure}" }
    unless failures.empty?
      warn "FAIL: #{failures.length} of #{checks} checks"
      exit 1
    end

    puts "PASS: #{checks} checks"
  end

  def status_ok?(status, expected)
    return !status.success? if expected == :nonzero

    status.exitstatus == expected
  end
end

CheckCore.run
