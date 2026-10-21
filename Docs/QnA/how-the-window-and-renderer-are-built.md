# How are the window and renderer built?

- **Recorded:** 2026-10-21
- **Last updated:** 2026-10-21

Everything native lives in [`metal/service.swift`](../../metal/service.swift)
(`AppDelegate`). The file has three sections: the GPU side, the AppKit window, and
the entry point.

## Window setup

[`metal/service.swift`](../../metal/service.swift)
(`AppDelegate.applicationDidFinishLaunching`) runs after AppKit starts:

1. Installs the minimal application menu in `installMainMenu`.
2. Creates the default Metal device, terminating with a diagnostic if none exists.
3. Creates an `MTKView` at 800 × 600 with `.bgra8Unorm`, the dark clear color, and
   a requested 60 frames per second.
4. Creates the `Renderer` and assigns it as the view delegate.
5. Creates a titled, closable, miniaturizable, resizable `NSWindow` with a minimum
   size of 360 × 360, centers it, and shows it.

The view is the window's `contentView`, so resizing the window resizes the
drawable. `applicationShouldTerminateAfterLastWindowClosed` returns `true`, which
is what lets closing the window end the process.

## Pipeline setup

[`metal/service.swift`](../../metal/service.swift) (`Renderer`) is an `NSObject` and
`MTKViewDelegate`. Its initializer creates the command queue, compiles the embedded
shader source, looks up `square_vertex` and `square_fragment`, and builds one
render pipeline whose color attachment pixel format matches the view.

The initializer is failable. A missing queue, library, function, or pipeline prints
a `[metal-service]` message and returns `nil`; the delegate then terminates the
application rather than running without a renderer.

## Per-frame work

[`metal/service.swift`](../../metal/service.swift) (`Renderer.draw`) does five things:

1. Computes the delta since `previousFrameTime`, clamped to `1/15` second, and
   advances the angle by `speed * delta`.
2. Obtains the current render pass descriptor, drawable, command buffer, and render
   encoder, returning early if any is unavailable.
3. Builds a `Uniforms` value containing the drawable width, height, and angle.
4. Sets the pipeline, passes the uniforms with `setVertexBytes`, and draws a
   four-vertex triangle strip.
5. Ends encoding, presents the drawable, and commits the command buffer.

`mtkView(_:drawableSizeWillChange:)` is intentionally empty: the drawable size is
read from the view every frame, so no cached size can go stale.

## Why one draw call

The scene is one quad. A vertex buffer, index buffer, texture, depth buffer, or
multiple pipelines would add state without adding capability. The shader generates
the four corners from `vertex_id`, rotates them around the origin, and applies the
aspect correction:

```text
point.x *= resolution.y / max(resolution.x, 1.0)
```

That line is what keeps the square square when the window is not square.
