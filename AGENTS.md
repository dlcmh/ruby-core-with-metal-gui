# AGENTS.md

Operating instructions for AI coding agents working in this repository. These
rules are mandatory unless the maintainer gives a direct instruction that
supersedes them. Update this file when project policy changes.

- **Project:** Ruby Core · Metal
- **Canonical repository:** <https://github.com/dlcmh/ruby-core-with-metal-gui>
- **Maintainer:** David Chin ([@dlcmh](https://github.com/dlcmh))
- **Governance baseline:** 2026-10-21
- **Current release:** none (unreleased baseline)

## Read first

1. [Docs/PROJECT_ORIGIN.md](Docs/PROJECT_ORIGIN.md) — why the project exists and
   the decisions made at each baseline. Its quoted request is a historical
   record and must not be edited.
2. [GOVERNANCE.md](GOVERNANCE.md) — decision-making, releases, licensing, and
   amendment rules.
3. [CONTRIBUTING.md](CONTRIBUTING.md) — build, verify, and contribution workflow.
4. [SECURITY.md](SECURITY.md) — vulnerability reporting and privacy posture.
5. [Docs/RUBY_METAL_DESIGN.md](Docs/RUBY_METAL_DESIGN.md) — the architecture and
   the rationale behind the Ruby/Swift split.
6. [Docs/QnA/README.md](Docs/QnA/README.md) and
   [Docs/Refactoring/README.md](Docs/Refactoring/README.md) — focused answers and
   recorded design decisions.

## Project layout

| Path | Responsibility |
| --- | --- |
| [`core.rb`](core.rb) | Ruby supervisor (`RubyMetalCore.run`). Parses arguments, builds the service when stale, launches it, forwards signals, and propagates its exit status. It renders nothing. |
| [`metal/service.swift`](metal/service.swift) | Native macOS service: AppKit window, MetalKit view, Metal pipeline (`Renderer`), embedded shaders, and the application entry point. |
| `build/` | Generated service binary and Swift module cache. Git-ignored. Never commit it. |
| `scripts/` | The `make check` gate, Ruby smoke checks, and the documentation checker. |
| `Docs/` | Origin record, design notes, Q&A entries, and Refactoring decisions. |

The repository is deliberately two source files plus tooling. Do not introduce a
directory tree, package manager, or build system without a governance decision.

## Prerequisites

- macOS 13 or newer on a Metal-capable Mac.
- Xcode Command Line Tools, providing `swiftc` (Swift 5.9 or newer).
- Ruby 2.6 or newer. The system Ruby is sufficient; there are no gems.
- Python 3 for the optional documentation checker. It is not needed at runtime.
- No Xcode project, Swift package, CocoaPods, Bundler, or runtime network
  service.

## Build, run, and verify

Run these from the repository root:

```sh
ruby core.rb                         # build if needed, then launch the window
ruby core.rb --speed 1.6             # radians per second
ruby core.rb --help                  # usage, exits without launching
make check                           # the full local gate
make docs-check                      # links, anchors, and cited symbols
make docs-impact                     # docs that reference files changed vs HEAD
make clean                           # remove build/
```

[`scripts/check.sh`](scripts/check.sh) (`main`) is the gate and runs:

1. `ruby -c core.rb` — supervisor syntax.
2. `ruby scripts/check_core.rb` — CLI and failure-path smoke checks that never
   open a window.
3. `swiftc -typecheck -warnings-as-errors` for the service, with an in-repo
   module cache under `build/module-cache`.
4. `python3 scripts/check_docs.py` — links, heading anchors, and cited symbols.

A Swift typecheck is necessary but not sufficient. The Metal shader is compiled
at runtime from an embedded string, so a typecheck can pass while launch fails.
After touching shaders, rendering, windowing, timing, or argument handling,
launch the app and confirm the window appears and the square rotates. Do not
claim a visual change works if you could not launch a GUI in your environment;
say exactly what was blocked.

## Non-negotiable architecture

1. **Keep the Ruby/Swift boundary.** [`core.rb`](core.rb)
   (`RubyMetalCore`) owns process lifecycle and argument validation only. The
   native service owns AppKit, Metal, windows, and drawing. Do not move rendering
   into Ruby or process supervision into Swift.
2. **Keep the process contract tiny.** The only inputs are the service command
   line (`--speed`), the inherited environment, and signals. The only outputs are
   stdout/stderr text, the window, and the exit status. Do not add sockets,
   pipes, shared memory, or a serialization protocol without a governance
   decision and an updated design record.
3. **Keep the native service self-contained.** [`metal/service.swift`](metal/service.swift)
   (`Renderer`) embeds its shader source and creates the pipeline in code. Do not
   add `.metal` files, asset bundles, storyboards, or nibs.
4. **Keep the build toolchain-native.** Compile with `swiftc` from
   [`core.rb`](core.rb) (`RubyMetalCore.compile_service`). Do not add Xcode
   projects, SwiftPM manifests, Make-driven compilation, or checked-in binaries.
5. **Keep the launch cache timestamp-based.** Rebuild only when
   `metal/service.swift` is newer than `build/metal-service`. If you change the
   compiler flags or embed other sources, update that check in the same change.
6. **Keep motion frame-rate independent and bounded.** Integrate elapsed time in
   [`metal/service.swift`](metal/service.swift) (`Renderer.draw`), clamp the delta
   to `1/15` second, and wrap the angle. Do not assume a fixed frame rate or
   advance by a constant per callback.
7. **Keep dependencies at zero.** Only the Ruby standard library and the macOS
   AppKit, Metal, MetalKit, and QuartzCore frameworks. No gems, no Swift
   packages, no vendored source.
8. **Keep the project offline.** No network calls, telemetry, analytics, remote
   configuration, or runtime downloads. The service makes no network requests.
9. **Keep failure loud.** Print diagnostics to stderr with the `[core]` or
   `[metal-service]` prefix and exit non-zero. Never swallow a compile or
   pipeline failure.
10. **Keep it macOS-native.** AppKit windows and menus, MetalKit view, Metal
    pipeline. Do not replace the shell with a cross-platform toolkit.

## Runtime invariants

Changes that affect the CLI, window, renderer, or lifecycle must preserve or
deliberately update these invariants and their checks:

- The default angular velocity is `0.9` radians per second.
- `--speed VALUE` accepts a finite `Float`; a missing, non-numeric, `NaN`, or
  infinite value prints usage to stderr and exits non-zero.
- `--help` and `-h` print usage to stdout and exit zero before compiling.
- The window opens at 800 × 600, is resizable, and has a minimum size of
  360 × 360.
- The quad is a four-vertex triangle strip scaled to `0.9`, rotated about its
  center, and corrected for the drawable aspect ratio.
- The clear color is approximately `(0.035, 0.04, 0.07, 1)` and the quad fill is
  approximately `(0.98, 0.44, 0.12, 1)`.
- Closing the window terminates the service, and the Ruby supervisor exits with
  the service's status.
- `INT` and `TERM` sent to Ruby are forwarded to the service.
- The service binary and module cache live under `build/` and are never tracked.

## Static checks

`make check` is the gate every change must pass. It must remain runnable with the
documented prerequisites: `ruby`, `swiftc`, `python3`, and POSIX `sh`.

- Do not add third-party linters, formatters, or test runners to the required
  gate without a governance decision.
- Ruby formatting follows the existing file: `# frozen_string_literal: true`,
  double-quoted strings, two-space indentation, and `module_function`.
- Swift formatting follows the existing file: four-space indentation, explicit
  access control, and `MARK` sections.
- The documentation checker is standard-library Python only.

## Testing standard

There is no unit-test framework, and the gate does not pretend otherwise. The
layers are:

- [`scripts/check_core.rb`](scripts/check_core.rb) (`CheckCore`) exercises the
  supervisor through its public CLI only: help output, missing and invalid speed
  values, and non-zero exits. It never compiles or opens a window.
- Swift typechecking catches API and syntax regressions in the service.
- [`scripts/check_docs.py`](scripts/check_docs.py) (`validate`) keeps
  documentation honest.
- A manual launch validates the shader, window, and visible rotation.

Add a smoke case when changing argument parsing or the supervisor's exit
behavior. Add a design note or Q&A entry when changing the process contract.
There is no meaningful headless substitute for checking the rendered frame.

A green baseline currently ends with:

```text
PASS: 18 checks
```

Counts may grow as cases are added. The requirement is that all checks pass.

## Documentation and code references

A line number in prose is wrong the moment ten lines are inserted above it, and
nothing fails. Documentation therefore cites a **file and a symbol**, never a line
range:

```markdown
[`service.swift`](metal/service.swift) — `Renderer`
```

- Link the file, then name the symbol in backticks on the same line or in the
  same sentence.
- Prefer the most specific symbol — a method, type, or constant — over a general
  word.
- Link Markdown by heading anchor
  (`../AGENTS.md#non-negotiable-architecture`), never by line.
- When a symbol is renamed or removed, update every document that cites it.

`make docs-check` enforces this: every relative link must resolve, every heading
anchor must exist, every cited symbol must still occur in the linked file, and
`#L` line anchors are rejected.

`make docs-impact` lists the documents that reference files changed against
`HEAD` (or `--base <rev>`) and warns when the diff removes a symbol one of them
cites. Treat that list as the re-read queue after changing code.

[Docs/PROJECT_ORIGIN.md](Docs/PROJECT_ORIGIN.md) is a historical record: its
quotation is immutable, so correct a stale reference there by annotating outside
the quote rather than rewriting it. A single line can opt out of the symbol rule
with `<!-- docs-check: ignore -->`.

## Git and release workflow

- `main` is the canonical trunk.
- `origin` is <git@github.com:dlcmh/ruby-core-with-metal-gui.git>.
- Use Conventional Commit messages, for example:
  - `feat: add --fullscreen flag`
  - `fix: forward TERM before waiting for the service`
  - `docs: record the process contract`
  - `chore: refresh build cache rules`
- Keep commits coherent and reviewable. Do not mix unrelated refactors with
  behavior changes.
- Run `make check` before committing.
- The maintainer has authorized repository agents to commit and push normal
  changes automatically. Commit with a Conventional Commit message and push to
  `origin/main` without waiting for a separate request.
- Still never force-push `main`, rewrite published history, or change remotes
  without explicit maintainer approval.
- Do not commit `build/`, `*.dSYM`, `.DS_Store`, module caches, or other
  generated intermediates.
- Do not create tags or GitHub Releases unless the maintainer asks.

## Rendering guidance

- Keep the single full-window MetalKit view and the one-pipeline, one-draw-call
  renderer. Do not add a scene graph, engine, or asset pipeline for this demo.
- Keep the shader source in Swift so the executable has no runtime resource
  dependencies.
- Prefer `setVertexBytes` for the small uniform block; if the payload grows,
  switch deliberately and document the buffer lifetime and synchronization.
- Preserve the window's resizable behavior and aspect-ratio correction.
- Do not introduce textures, external fonts, or sound without a stated need and
  a governance decision.

## Persistence and privacy

The service stores nothing. It does not write preferences, caches, logs, or
telemetry. The only filesystem write is the supervisor's build artifact under
`build/`. If a persisted setting becomes necessary, document it here and in
[SECURITY.md](SECURITY.md) before adding it.

## Legal and licensing

- No open-source license has been selected for this repository. Do not add a
  license, relicense code, or claim reuse rights without explicit maintainer
  approval.
- Only contribute original code. Do not paste code from projects whose license is
  incompatible or undocumented.
- AppKit, Metal, MetalKit, and QuartzCore are Apple frameworks used under the
  macOS SDK terms; this project does not redistribute them.
- This is a demonstration project and is not affiliated with or endorsed by
  Apple.

## Agent operating protocol

1. Read this file, the origin record, the design notes, and the relevant source
   before editing.
2. Inspect `git status` and preserve unrelated local work.
3. Make the smallest coherent change that satisfies the request.
4. Add or update smoke checks and documentation for behavioral changes.
5. Run `make check`; launch the app for presentation, shader, or lifecycle
   changes.
6. Update README/governance docs when behavior, controls, or policy changes, then
   run `make docs-check` and resolve the docs listed by `make docs-impact`.
7. Commit with a Conventional Commit message and push to `origin/main`.
8. Report what changed, what was verified, and any remaining risks or follow-up
   work.

Do not claim to have run something you did not run. If the environment prevents a
verification step, say exactly what was blocked.

## Definition of done

- [ ] `make check` passes: Ruby syntax, CLI smoke checks, Swift typecheck, docs.
- [ ] `make docs-check` passes, and docs listed by `make docs-impact` were re-read
      after code changes.
- [ ] The app launches and the square rotates when presentation or lifecycle
      changed.
- [ ] CLI and runtime documentation is current.
- [ ] Governance and origin records remain accurate.
- [ ] No generated binaries or secrets are staged.
- [ ] Change is committed and pushed to `origin/main`.

## When to stop and ask the maintainer

Ask before:

- changing licensing, repository visibility, or the canonical remote;
- adding dependencies, assets, telemetry, network access, or persistence;
- changing the process contract or adding inter-process communication;
- replacing AppKit/MetalKit with another windowing or rendering stack;
- adding packaging, notarization, or public distribution;
- force-pushing or rewriting published history; or
- implementing large optional scope such as multiple objects, controls, or a
  reusable engine.
