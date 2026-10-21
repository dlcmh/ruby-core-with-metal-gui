# Ruby supervisor over a single Swift application

- **Recorded:** 2026-10-21
- **Last updated:** 2026-10-21
- **Status:** Accepted

## Context

The repository demonstrates a Ruby process launching and supervising a native
Metal renderer. That requires at least two processes or an FFI bridge. The
question is where to put the boundary and how much the two sides should know about
each other.

## Decision

Keep a small Ruby supervisor, [`core.rb`](../../core.rb) (`RubyMetalCore`), and a
standalone Swift executable, [`metal/service.swift`](../../metal/service.swift)
(`Renderer`). The supervisor builds the service when stale, spawns it with a
`--speed` argument, forwards `INT`/`TERM`, and exits with the service's status. The
two processes share no memory and no protocol.

## Options considered

| Option | Advantages | Costs | Outcome |
| --- | --- | --- | --- |
| Ruby supervisor + Swift executable | Clear boundary; each language does its job; service can be launched directly; no FFI | Two processes; contract limited to argv/stdio/signals/status | **Chosen** |
| One Swift application | Simplest runtime; one build artifact | Removes the Ruby supervision that the repository exists to demonstrate | Rejected |
| Ruby FFI into AppKit/Metal | One process; Ruby controls the window | Large, fragile binding surface; memory-management risk; hard to typecheck | Rejected |
| Ruby supervisor + socket or pipe protocol | Richer communication; potential for runtime control | Needs framing, versioning, lifecycle, and error handling for no current feature | Rejected as premature |
| Xcode project or SwiftPM package | Standard Swift tooling; easier to add targets | Adds generated project state and a second build system for one source file | Rejected |

## Evidence

- The supervisor is 77 lines and contains no rendering knowledge. It validates
  arguments, compares two modification times, runs one compiler command, and waits.
- The service is independently runnable: `build/metal-service --speed 1.6` opens
  the same window without Ruby.
- The only coupling is the `--speed` flag, which both sides parse. Even that is
  duplicated deliberately so the service does not depend on the supervisor.
- The native service uses AppKit, MetalKit, Metal, and QuartzCore directly, with no
  bridging layer to audit.

## Consequences

- Adding a feature that needs both processes to exchange state requires a real
  protocol design; that is a governance-level change, not a local refactor.
- Build invalidation is timestamp-based and only watches the Swift source. Changing
  compiler flags or the toolchain requires a clean build.
- The service cannot be unit-tested through Ruby, so verification is split:
  supervisor CLI smoke checks in Ruby, Swift typechecking, and a manual launch for
  visual behavior.
- Distribution would need to ship both the Ruby script and the compiled service, or
  replace the supervisor. Packaging is out of scope.

## Revisit triggers

Revisit this decision if any of the following becomes true:

- the supervisor needs to react to renderer state or restart it automatically;
- the service needs to be embedded in another application;
- distribution requires a single signed bundle;
- the Ruby dependency becomes a barrier for users; or
- the process contract grows beyond a handful of command-line flags.

See [../RUBY_METAL_DESIGN.md](../RUBY_METAL_DESIGN.md) for the full architecture.
