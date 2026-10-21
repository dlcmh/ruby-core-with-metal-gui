# Can this demo break the internet?

- **Recorded:** 2026-10-21
- **Last updated:** 2026-10-21

**Short answer: not today — but the part worth being excited about is real.** This
entry records a lighthearted exchange after the first successful launch. It is an
engineering take, not a roadmap or a release promise.

## The exchange

> **Maintainer:** can't believe you made something that worked so well - we
> probably will break the internet today - what's your take?
>
> **Agent:** Ha — love the energy. My honest take: it's a clean foundation, not an
> internet-breaking one yet.

## What is genuinely solid

- **The boundary is clear.** [`core.rb`](../../core.rb) (`RubyMetalCore`) owns
  process lifecycle, and [`metal/service.swift`](../../metal/service.swift)
  (`Renderer`) owns the window and the GPU. Neither side pretends to do the other's
  job.
- **It starts with one command and zero dependencies.** The Ruby core compiles the
  native service with `swiftc` when needed, then launches it. There is no package
  manager, project file, or runtime download in the way.
- **The small details are right.** [`metal/service.swift`](../../metal/service.swift)
  (`Renderer.draw`) uses delta time instead of a fixed per-frame step and wraps the
  angle. The vertex shader corrects for aspect ratio, so resizing does not turn the
  square into a rectangle.
- **The lifecycle is honest.** Closing the window ends the service, and the Ruby
  supervisor exits with the same status. `INT` and `TERM` are forwarded.

That is a respectable amount of foundation for two source files.

## What still keeps it small

- **There is no communication protocol.** The process contract is currently the
  `--speed` argument, inherited stdio, signals, and an exit status. Ruby cannot
  send draw commands to the service.
- **The native side is a loose executable**, not a signed or packaged app bundle.
- **The renderer is intentionally one quad.** There is no scene model, input
  handling, asset pipeline, or restart policy.

Those are not flaws in a demo this size. They are the edges that define it.

## The fun next step

The internet-breaking version is not a faster spinning square. It is making Ruby
the creative surface for a native renderer — for example, a tiny JSON-lines
protocol so Ruby can describe what to draw.

That would change the process contract, so it needs a governance decision and an
updated design record rather than an enthusiastic commit. See
[`AGENTS.md`](../../AGENTS.md#non-negotiable-architecture).

For now, the honest take stands: a rotating square that just works is a perfectly
respectable amount of damage.
