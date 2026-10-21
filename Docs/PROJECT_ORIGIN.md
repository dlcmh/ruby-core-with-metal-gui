# Project Origin and Decision Record

This document preserves the request that established the governance baseline for
**Ruby Core · Metal** and records the decisions that shape the repository. It is a
historical and governance document. The **Original request** block below is
immutable.

- **Project:** Ruby Core · Metal
- **Repository:** <https://github.com/dlcmh/ruby-core-with-metal-gui>
- **Maintainer:** David Chin ([@dlcmh](https://github.com/dlcmh))
- **Governance baseline:** 2026-10-21
- **Delivery agent:** DeepSeek Harness (deepseek-flash)
- **Initial implementation commits:** `e6167f6` (Ruby core and Metal service),
  `221253f` (ignore rules)
- **Reference repository for governance shape:**
  `/Users/dlcmh/dev/1978-space-invaders-in-rust-on-macos`

## Original request

The following is the human-authored request that commissioned this governance
baseline, verbatim. Harness-supplied runtime metadata that followed it — the
working directory, file policy, approval policy, GUI URL, and checkout path — is
not part of the quote.

```text
i'd like this repo to follow governance conventions, agents md, etc based on eg /Users/dlcmh/dev/1978-space-invaders-in-rust-on-macos
```

## Requirements captured from the request

1. Adopt the governance conventions of the referenced repository: agent operating
   instructions, contribution rules, decision-making, security policy, project
   origin, design notes, and recorded decisions.
2. Adapt those conventions to this repository's actual scope rather than copying
   Rust/Cargo commands that do not exist here.
3. Provide a verification gate that runs with the project's real prerequisites:
   `ruby`, `swiftc`, `python3`, and POSIX `sh`.
4. Preserve the existing behavior: a Ruby supervisor that compiles and launches a
   Swift + MetalKit service showing one rotating square.
5. Keep documentation references durable by citing files and symbols rather than
   line numbers, and enforce that with a checker.
6. Do not add dependencies, assets, network access, packaging, or unrelated
   features as part of the governance pass.

## Repository origin

The implementation predates the governance baseline. Commit `e6167f6` added the
two-process demonstration:

- [`core.rb`](../core.rb) (`RubyMetalCore`) validates arguments, compiles
  `metal/service.swift` when the binary is stale, launches it, forwards `INT` and
  `TERM`, and propagates its exit status.
- [`metal/service.swift`](../metal/service.swift) (`Renderer`) creates the AppKit
  window, MetalKit view, pipeline, embedded shaders, and delta-time rotation.

Commit `221253f` added ignore rules for Swift build products, Bundler directories,
and macOS metadata.

The governance pass added [AGENTS.md](../AGENTS.md),
[GOVERNANCE.md](../GOVERNANCE.md), [CONTRIBUTING.md](../CONTRIBUTING.md),
[SECURITY.md](../SECURITY.md), this record,
[Docs/RUBY_METAL_DESIGN.md](RUBY_METAL_DESIGN.md), the
[Q&A](QnA/README.md) and [Refactoring](Refactoring/README.md) indexes, and the
`make check` tooling.

## Explicit scope decisions

| Topic | Decision |
| --- | --- |
| Platform | Native macOS only; no web, iOS, Windows, or Linux target. |
| Languages | Ruby for process supervision; Swift for AppKit/Metal presentation. |
| Boundary | One-way process contract: command-line arguments, inherited stdio, signals, and exit status. No IPC. |
| Rendering | MetalKit `MTKView` with one pipeline, one draw call, and an embedded MSL source string. |
| Build | `swiftc` invoked by the Ruby supervisor; no Xcode project, SwiftPM manifest, or Bundler setup. |
| Dependencies | None beyond the Ruby standard library and Apple frameworks. |
| Runtime data | None persisted. Only `build/` is written. |
| Distribution | Not packaged, signed, notarized, or released. |
| Tests | CLI smoke checks, Swift typechecking, and documentation validation; visual behavior requires a launch. |
| Licensing | No open-source license selected. See [GOVERNANCE.md](../GOVERNANCE.md). |

## Runtime context at commissioning

- Workspace: `/Users/dlcmh/dev/ruby-core-with-metal-gui`
- Host platform: macOS on Apple silicon
- Toolchain observed: Ruby 2.6.10, Swift 6.3.3, Python 3.14.7
- Interaction surface: DeepSeek Harness Web GUI
- File policy: workspace-write
- Repository state: `main` tracking `origin/main`, clean before the governance
  pass

These facts explain implementation choices and are not ongoing requirements.

## Verification record

The governance baseline is verified locally with `make check`, which runs Ruby
syntax checking, the CLI smoke suite, a Swift typecheck with warnings denied, and
the documentation checker. The baseline run reports `PASS: 18 checks` and
`OK: 5 code file(s) referenced by docs, all links and cited symbols resolve`.

The visual behavior was not re-verified during the governance pass because the
change set contains no rendering, shader, windowing, timing, or lifecycle code.
Launch the app with `ruby core.rb` when changing those areas.

## Governance directive

The original request asked for the referenced repository's governance conventions.
That established [AGENTS.md](../AGENTS.md), [CONTRIBUTING.md](../CONTRIBUTING.md),
[GOVERNANCE.md](../GOVERNANCE.md), [SECURITY.md](../SECURITY.md), this record,
[Docs/RUBY_METAL_DESIGN.md](RUBY_METAL_DESIGN.md), and the
[Q&A](QnA/README.md) and [Refactoring](Refactoring/README.md) indexes. The
canonical remote is `origin`:
<git@github.com:dlcmh/ruby-core-with-metal-gui.git>. The canonical browse URL is
<https://github.com/dlcmh/ruby-core-with-metal-gui>.

## Automatic commit and push directive

On 2026-10-21, after the governance baseline was committed, the maintainer
directed: "you shall auto commit and push from now on - record this directive
somewhere aprropriate". The spelling is preserved because this is a quotation.

This authorizes repository agents to commit and push normal changes to
`origin/main` without a separate request. It supersedes the earlier
"commit when the maintainer asks" phrasing. Destructive operations —
force-pushing, rewriting published history, or changing the canonical remote —
still require explicit approval, as recorded in [AGENTS.md](../AGENTS.md) and
[GOVERNANCE.md](../GOVERNANCE.md).

## Record maintenance

- Do not edit the **Original request** quotation.
- Append material decisions rather than silently rewriting history.
- Update the verification section when the baseline or gate changes.
- Changes to governance itself follow [GOVERNANCE.md](../GOVERNANCE.md).
