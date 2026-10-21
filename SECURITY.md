# Security Policy

## Supported versions

| Version | Supported |
| --- | --- |
| `main` | Yes |
| Older snapshots | No |

The project is a local demonstration. There is no server component and no network
access.

## Reporting a vulnerability

Please **do not open a public GitHub issue** for a suspected security
vulnerability.

Report it privately through GitHub's private vulnerability reporting:

<https://github.com/dlcmh/ruby-core-with-metal-gui/security/advisories/new>

If private advisories are unavailable, contact the maintainer
[@dlcmh](https://github.com/dlcmh) through GitHub and request a private channel.
Do not include exploit details in a public issue.

In your report, include:

- the affected commit;
- macOS, Xcode Command Line Tools, Ruby, and hardware details;
- a concise description of the issue and its impact;
- reproduction steps or a minimal proof of concept; and
- any suggested mitigation.

## Response expectations

This is a volunteer-maintained demonstration. The maintainer will make a best
effort to acknowledge reports, assess severity, and coordinate a fix and
disclosure. No response-time or remediation SLA is offered, and no bug bounty is
available.

Please allow reasonable time for a fix before public disclosure. The maintainer
will coordinate disclosure timing with the reporter.

## Scope

The intended attack surface is deliberately small:

- a local Ruby script that validates arguments and spawns a binary it builds from
  a fixed source path;
- a native macOS application that runs locally;
- no network requests, telemetry, accounts, or remote configuration;
- no runtime asset downloads;
- no third-party dependencies; and
- no persisted preferences.

Reports are in scope when they describe a concrete security impact in this
repository, for example unsafe process invocation, unexpected data access, a
compromised build path, or a memory-safety issue at the Swift/Metal boundary.

Out of scope includes:

- social engineering and physical access to an unlocked machine;
- vulnerabilities in macOS, the Xcode toolchain, Swift, Metal, or the user's
  hardware that are not caused by this project;
- issues requiring a malicious local user to replace the source, the built
  binary, or the toolchain before launch;
- denial-of-service from passing pathological but valid speed values or resizing
  the window to extreme sizes;
- licensing questions (see [GOVERNANCE.md](GOVERNANCE.md)); and
- reports against unofficial forks or modified distributions.

## Local data and privacy

The application stores nothing. It does not read or write preferences, caches,
logs, analytics, or telemetry. The only filesystem write is the supervisor's
compiled service under `build/`, plus the Swift module cache used by the check
gate.

## Build integrity

- The service is built from `metal/service.swift` with `swiftc` on the local
  machine.
- [`core.rb`](core.rb) (`RubyMetalCore.compile_service`) invokes `swiftc` with a
  fixed argument list and a fixed output path; it does not use a shell.
- The shader is compiled at runtime by Metal from an embedded string; there is no
  downloaded shader or resource.
- No prebuilt binary is committed to the repository.
- There is no lockfile because there are no third-party dependencies.
- Do not download or run third-party modified builds claiming to be official.
- The canonical source is
  <https://github.com/dlcmh/ruby-core-with-metal-gui>.

## Native and unsafe code policy

The service is written in Swift and does not use `unsafe` APIs. Its sensitive
operations are at the Metal boundary:

- [`metal/service.swift`](metal/service.swift) (`Renderer.draw`) passes a
  stack-allocated `Uniforms` value to `setVertexBytes` with
  `MemoryLayout<Uniforms>.stride`; the size must match the shader's `Uniforms`
  layout.
- The embedded shader's `Uniforms` struct and the Swift `Uniforms` struct must
  keep the same field order and scalar types.
- Render pass, drawable, and command-buffer lifetimes are managed by MetalKit and
  must not be extended beyond the callback.

Changes to those areas should be reviewed with particular care. A layout mismatch
is a correctness bug and may become a memory-safety issue.

## Dependency policy

The accepted dependency baseline is the Ruby standard library and the macOS
AppKit, Metal, MetalKit, and QuartzCore frameworks. Any proposed gem, Swift
package, or vendored source requires maintainer approval and a review of its
security, licensing, and maintenance impact. See
[GOVERNANCE.md](GOVERNANCE.md).

## Legal and project context

See [GOVERNANCE.md](GOVERNANCE.md) for licensing and project policy.
