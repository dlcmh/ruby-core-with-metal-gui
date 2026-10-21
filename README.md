# ruby-core-with-metal-gui

A deliberately small demo of a Ruby process launching a native Metal rendering
service. The Ruby core supervises the service; a Swift + MetalKit executable
owns the window and draws one rotating square at 60 fps.

## Run

```sh
ruby core.rb
# Optionally change the angular velocity (radians per second):
ruby core.rb --speed 1.6
```

The first launch compiles `metal/service.swift` with `swiftc` into
`build/metal-service`. Later launches reuse that binary unless the source has
changed. Close the window or press Ctrl-C in the terminal to stop both the
service and the Ruby core.

Requirements: macOS with Metal support, the Xcode Command Line Tools (for
`swiftc`), and Ruby. There are no gems or other dependencies.

## Layout

```text
core.rb                 Ruby core: builds, launches, and supervises the service
metal/service.swift     AppKit window, Metal pipeline, embedded shaders
build/                  Generated executable (ignored by git)
```

## How it works

1. `core.rb` checks the source timestamp, compiles the Swift service when
   needed, then starts it with `Process.spawn`.
2. The Swift service creates an 800×600 `NSWindow` backed by an `MTKView`.
3. A tiny vertex shader rotates a four-vertex triangle strip around its center;
   the fragment shader fills it with a single orange color. The vertex shader
   corrects for window aspect ratio and the 60 fps draw loop updates the angle.
4. Ruby forwards `INT`/`TERM` to the service and waits for it to exit. Closing
   the window terminates the service, which in turn ends the Ruby core.

The shader source is embedded as a Swift string so there are no `.metal` build
steps or resource files to manage.
