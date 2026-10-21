# Ruby / Metal Design Notes

This document records the engineering choices behind **Ruby Core · Metal**. It is
meant to be read before changing the architecture, and it explains why the
repository looks the way it does rather than merely describing what each file
contains.

The short version: **Ruby owns the process, Swift owns the window, and Metal owns
the pixels.** There is no shared runtime, no IPC protocol, and no build system
beyond the one command the supervisor runs.

## 1. Two processes, two responsibilities

| Process | Source | Owns | Does not own |
| --- | --- | --- | --- |
| Ruby supervisor | [`core.rb`](../core.rb) (`RubyMetalCore`) | argument parsing, build invalidation, spawn, signal forwarding, exit status | windows, graphics, GPU state |
| Swift service | [`metal/service.swift`](../metal/service.swift) (`Renderer`) | AppKit lifecycle, window, MetalKit view, pipeline, shaders, frame timing | build decisions, process supervision |

Why split at a process boundary rather than link Ruby and Swift?

- Each language does what it is good at: Ruby for concise orchestration, Swift for
  direct AppKit and Metal access.
- The boundary is visible and enforceable. The renderer cannot reach into the
  supervisor's state, and the supervisor cannot reach into the renderer's objects.
- The service is an ordinary executable. It can be launched, inspected, and
  terminated without Ruby, which makes failures easier to diagnose.
- There is no FFI layer, no bridging header, and no shared memory lifetime to
  reason about.

The cost is that the two processes can only exchange what the operating system
already provides: arguments, stdio, signals, and an exit status. That limitation is
intentional. A richer contract would need a protocol, framing, error handling, and
its own tests, which is out of scope for this demonstration.

## 2. The process contract

The contract is deliberately tiny:

- **Input:** `--speed RADIANS_PER_SECOND`, or `--help`/`-h`.
- **Output:** human-readable lines on stdout/stderr prefixed `[core]` or
  `[metal-service]`.
- **Signals:** `INT` and `TERM` are forwarded from Ruby to the service.
- **Termination:** closing the window ends the service; the supervisor waits and
  exits with the same status.

[`core.rb`](../core.rb) (`RubyMetalCore.run`) performs the spawn and wait. It does not
poll, restart, or interpret the service's output. If you add a restart policy or a
new message, the contract changes and this document must change with it.

Argument validation lives in [`core.rb`](../core.rb)
(`RubyMetalCore.parse_args`). The service parses the same flag again in
[`metal/service.swift`](../metal/service.swift) (`requestedSpeed`) so it remains
independently launchable. Keep the two parsers consistent: both accept a finite
`Float`, both default to `0.9`, and both exit for `--help`. The service's fallback
is permissive because the supervisor already validates; a direct launch with a bad
value falls back to the default rather than refusing to start.

## 3. Build on launch

[`core.rb`](../core.rb) (`RubyMetalCore.compile_service`) compares the modification
times of `metal/service.swift` and `build/metal-service`. It rebuilds only when the
source is newer or the binary is missing.

Why this shape?

- A fresh clone works with one command and no separate build step.
- No generated Xcode project or Swift package adds files that can drift from the
  source of truth.
- The cache key is simple and visible. The tradeoff is that changing compiler
  flags, the Swift toolchain, or an embedded file that is not the service source
  will not invalidate the binary. If that happens, run `make clean` or extend the
  check in the same change.
- The binary path is derived from the repository root, not the caller's working
  directory, so the command works from anywhere.

The compiler invocation uses an argument array with `system`, not a shell string.
That avoids quoting bugs and keeps the command auditable.

## 4. The renderer

[`metal/service.swift`](../metal/service.swift) (`Renderer`) is a single
`MTKViewDelegate`:

1. Create the command queue and render pipeline once, from the embedded shader.
2. On each draw, advance the angle from elapsed time.
3. Build a small `Uniforms` value with the drawable size and angle.
4. Encode one triangle-strip draw of four vertices.
5. Present the drawable and commit the command buffer.

The drawable size is read from the view rather than the window, so Retina scaling
is handled by MetalKit. The vertex shader divides x by the aspect ratio, keeping the
quad square at any window size.

There is no depth buffer, no texture, no vertex buffer, and no per-object state.
The four corners are a constant array in the shader, and the uniform block is passed
with `setVertexBytes`. This is appropriate for one quad; it would not scale to a
scene, which is why a scene graph is out of scope.

## 5. Embedded shaders

[`metal/service.swift`](../metal/service.swift) (`shaderSource`) stores the Metal
Shading Language in a Swift multi-line string.
[`metal/service.swift`](../metal/service.swift) (`Renderer.init`) compiles it at
runtime with `makeLibrary(source:options:)`.

Consequences:

- The executable has no runtime asset dependencies.
- Shader errors surface at launch, not at compile time, so a clean `swiftc`
  typecheck does not prove the shader is valid.
- The Swift `Uniforms` struct and the MSL `Uniforms` struct must agree on field
  order and type. They are intentionally adjacent in the file to make that
  comparison easy.

The alternative — a `.metal` file compiled into a `metallib` — would catch shader
errors earlier, but adds a build step and a resource to locate at runtime. For a
single embedded shader, the current tradeoff is better.

## 6. Time and motion

[`metal/service.swift`](../metal/service.swift) (`Renderer.draw`) uses
`CACurrentMediaTime`, clamps the delta to a maximum of `1/15` second, and wraps the
angle with `truncatingRemainder(dividingBy: .pi * 2)`.

- Clamping prevents a huge jump after a debugger pause, window drag, or sleep.
- Wrapping keeps the angle bounded so the sine and cosine stay well-conditioned.
- Integrating by elapsed time keeps the rotation speed consistent across display
  refresh rates and frame drops.

The view requests 60 frames per second, but the motion does not depend on that
number. Do not replace the delta integration with a fixed increment per callback.

## 7. Failure handling

- A missing Metal device, pipeline, command queue, or shader function terminates
  the service with a `[metal-service]` diagnostic and a non-zero exit.
- A failed `swiftc` invocation aborts the supervisor with `[core] compilation
  failed`.
- Invalid arguments print usage to stderr and exit non-zero.
- `INT`/`TERM` are forwarded; `Errno::ESRCH` is ignored because it means the
  service already exited.

The design does not attempt to recover from a failed launch. For a demo, a clear
error and a non-zero status are more useful than an automatic retry loop.

## 8. Alternatives evaluated

| Alternative | Why not chosen |
| --- | --- |
| One Swift application | Loses the Ruby supervision demonstration, which is the point of the repository. |
| Ruby FFI into AppKit/Metal | Large, fragile binding surface; Swift already has direct framework access. |
| Socket or pipe IPC | Adds framing, lifecycle, and error handling with no current use case. |
| Xcode project or SwiftPM | Adds project files and build state that the one-command launch does not need. |
| `.metal` file and `metallib` | Adds a build artifact and runtime lookup for a single shader. |
| Game engine or scene graph | Far more machinery than one rotating quad justifies. |

The Ruby/Swift decision is recorded in
[Refactoring/ruby-supervisor-over-single-swift-app.md](Refactoring/ruby-supervisor-over-single-swift-app.md).

## 9. Extension rules

Before extending the repository, decide which side of the boundary the change
belongs to:

- Process behavior, argument validation, and build invalidation belong in
  [`core.rb`](../core.rb) (`RubyMetalCore`).
- Window, GPU, shader, and frame behavior belong in
  [`metal/service.swift`](../metal/service.swift) (`Renderer`).
- A change that needs both sides to exchange new data changes the process contract
  and requires a governance decision plus an updated record.

Keep the demonstration small. A second object, a texture, or a user control is
still within reach; a reusable engine is not the goal.

## 10. Documentation map

- [AGENTS.md](../AGENTS.md) — agent operating rules and invariants.
- [GOVERNANCE.md](../GOVERNANCE.md) — decision-making and policy.
- [PROJECT_ORIGIN.md](PROJECT_ORIGIN.md) — the commissioning record.
- [QnA/README.md](QnA/README.md) — focused answers about the implementation.
- [Refactoring/README.md](Refactoring/README.md) — recorded design decisions.
