# Contributing to Ruby Core · Metal

Thanks for your interest. This is a deliberately compact demonstration of a Ruby
process supervising a native Metal renderer. Focused contributions that preserve
that shape are welcome.

Before changing anything, read [AGENTS.md](AGENTS.md),
[Docs/PROJECT_ORIGIN.md](Docs/PROJECT_ORIGIN.md),
[Docs/RUBY_METAL_DESIGN.md](Docs/RUBY_METAL_DESIGN.md), and
[GOVERNANCE.md](GOVERNANCE.md).

## Prerequisites

- macOS 13 or newer on a Metal-capable Mac
- Xcode Command Line Tools, providing `swiftc` (Swift 5.9 or newer)
- Ruby 2.6 or newer (the system Ruby is sufficient)
- Python 3, only for `make docs-check`
- Git

No Xcode project, Swift package, Bundler setup, or runtime package manager is
required.

## Build and run

```sh
ruby core.rb
ruby core.rb --speed 1.6
```

The first launch compiles `metal/service.swift` into `build/metal-service` and
later launches reuse it while the source is unchanged. `ruby core.rb --help`
prints usage without compiling or opening a window.

Generated files under `build/` (the binary and the Swift module cache) are
deliberately not versioned.

## Verify changes

```sh
make check
```

That runs the full gate:

1. `ruby -c core.rb`
2. `ruby scripts/check_core.rb`
3. `swiftc -typecheck -warnings-as-errors` for the service
4. `python3 scripts/check_docs.py`

Individual stages are available as `make docs-check` and `make docs-impact`; run
the commands directly when debugging one stage.

Ruby style follows the existing file: `# frozen_string_literal: true`,
double-quoted strings, two-space indentation, and `module_function`. Swift style
follows the existing file: four-space indentation, explicit access control, and
`MARK` sections. There is no third-party formatter in the required gate; match the
surrounding code.

For shader, rendering, windowing, timing, or lifecycle changes, launching the app
is mandatory. The Metal shader compiles at runtime from an embedded string, so a
successful typecheck cannot validate it. Confirm the window appears, the square
rotates, resizing preserves its shape, and closing the window ends both
processes.

Documentation links and symbol references are checked too:

```sh
make docs-check
```

Prose cites a file and a symbol — never a line number — and the checker verifies
that every cited symbol still exists in the linked file. See
[AGENTS.md](AGENTS.md#documentation-and-code-references). After changing code,
`make docs-impact` lists the documents that reference the files you touched.

## Where to make changes

- **Supervisor and CLI:** [`core.rb`](core.rb) — `RubyMetalCore`.
- **Window, renderer, and shaders:** [`metal/service.swift`](metal/service.swift)
  — `Renderer`.
- **Checks and tooling:** `scripts/`.
- **User docs:** `README.md`.
- **Design and Q&A docs:** `Docs/RUBY_METAL_DESIGN.md` and `Docs/QnA/`.
- **Decision records:** `Docs/Refactoring/`.
- **Governance docs:** `AGENTS.md`, `GOVERNANCE.md`, this file, `SECURITY.md`, and
  `Docs/PROJECT_ORIGIN.md`.

## Quality bar

A contribution is ready when:

- `make check` passes;
- `make docs-check` passes, and docs affected by the change were re-read;
- rendering and lifecycle changes were visually checked by running the app;
- runtime invariants documented in [AGENTS.md](AGENTS.md#runtime-invariants) still
  hold, or the change explicitly updates them along with checks and docs;
- no new gem, Swift package, asset, telemetry, network access, or persistence was
  introduced without approval; and
- user-facing documentation is current.

## Style

- Keep the Ruby supervisor small and procedural. It should not know how to draw.
- Keep the Swift service self-contained. Window setup, pipeline creation, and
  drawing belong there.
- Keep functions and types focused and readable.
- Preserve bounded, frame-rate-independent motion. Do not advance by a constant
  per callback.
- Keep the shader embedded in Swift so the executable needs no runtime resources.
- Keep diagnostics on stderr with the established `[core]` and `[metal-service]`
  prefixes.
- Avoid adding dependencies. Discuss a proposed dependency with the maintainer
  before writing code around it.

## Workflow

1. Open an issue for a substantial behavior change or new scope.
2. Branch from `main` using a descriptive name, for example
   `feat/window-title` or `fix/signal-forwarding`.
3. Make a coherent change with checks and docs.
4. Run the verification above.
5. Commit using a Conventional Commit message:
   - `feat: ...`
   - `fix: ...`
   - `docs: ...`
   - `perf: ...`
   - `refactor: ...`
   - `chore: ...`
6. Open a pull request describing the change, verification performed, and any
   known limitations.

Repository agents are authorized to commit and push normal changes directly to
`main`; see `AGENTS.md`. Human contributors should use pull requests unless the
maintainer says otherwise.

## Reporting bugs

Use the repository issue tracker and include:

- macOS, Xcode Command Line Tools, and Ruby versions;
- steps to reproduce;
- expected and observed behavior;
- the relevant terminal output, including `[core]` and `[metal-service]` lines;
- a screenshot or short recording for visual issues; and
- whether the issue reproduces after `make clean` and a fresh launch.

Please do not include secrets, personal information, or unredacted local paths in
public reports.

## Security

Do not open a public issue for a suspected vulnerability. Follow
[SECURITY.md](SECURITY.md).

## Conduct

Be constructive, specific, and respectful. Harassment, discrimination, personal
attacks, and deliberately disruptive behavior are not welcome. The maintainer may
moderate, close, or block participation to keep the project healthy.

## Licensing and intellectual property

No open-source license has been selected for this repository. Do not assume that
code may be reused or redistributed beyond this project. Only submit original work
or material with a documented compatible license. Adding a license or changing the
project's licensing requires explicit maintainer approval.

AppKit, Metal, MetalKit, and QuartzCore are Apple frameworks used under the macOS
SDK terms. This project is not affiliated with or endorsed by Apple.

For decisions about scope, releases, and repository policy, see
[GOVERNANCE.md](GOVERNANCE.md).
