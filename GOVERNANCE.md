# Governance

This document defines how **Ruby Core · Metal** is maintained, how decisions are
made, and how releases and legal obligations are handled. It is intentionally
lightweight for a small demonstration project.

- **Canonical repository:** <https://github.com/dlcmh/ruby-core-with-metal-gui>
- **Canonical branch:** `main`
- **Maintainer:** David Chin ([@dlcmh](https://github.com/dlcmh))
- **Governance baseline:** 2026-10-21
- **Version covered:** unreleased development baseline

## Mission and scope

The project is a minimal, native macOS demonstration of two cooperating runtimes:
a **Ruby core** that owns process lifecycle, and a **Swift + Metal service** that
owns the window and GPU rendering. Its quality priorities are a clean process
boundary, a dependency-free build, readable code, reproducible local behavior,
and documentation that matches the code.

### In scope

- The Ruby supervisor: argument validation, build-on-launch, spawn, signal
  forwarding, and exit-status propagation.
- The native service: AppKit window and menu, MetalKit view, Metal pipeline,
  embedded shaders, and bounded delta-time rotation.
- A deterministic, timestamp-based build cache for the service binary.
- Shell, Ruby, Swift, and documentation checks that run locally with the
  documented prerequisites.
- Documentation, Q&A entries, and recorded design decisions.

### Explicitly excluded unless re-scoped

- Network access, telemetry, analytics, accounts, remote configuration, or
  runtime downloads.
- Web, iOS, Windows, or Linux ports.
- Gems, Swift packages, Xcode projects, storyboards, asset catalogs, or other
  dependency and build-system layers.
- External shader files, textures, fonts, audio, or bundled resources.
- Persistence of settings, window state, scores, or logs.
- Packaging, signing, notarization, or public distribution.
- A general-purpose scene graph, engine, or reusable rendering library.

Scope changes require the process described under **Decision making**.

## Roles

### Maintainer

The maintainer has final responsibility for:

- repository direction, roadmap, and scope;
- merging and publishing changes;
- releases, tags, signing, and distribution;
- licensing decisions;
- security response; and
- amendments to governance documents.

The current sole maintainer is [@dlcmh](https://github.com/dlcmh).

### Contributors

Contributors propose fixes, features, documentation, and checks through issues,
pull requests, or maintainer-authorized direct pushes. Contributions are reviewed
against the quality bar in [CONTRIBUTING.md](CONTRIBUTING.md) and the
architectural rules in [AGENTS.md](AGENTS.md).

### Users

Users may report bugs and request features through the GitHub issue tracker.
Security reports must follow [SECURITY.md](SECURITY.md).

## Decision making

The project uses a **maintainer-led** model:

- Day-to-day fixes and documentation improvements proceed through normal review.
- Changes to the process contract, dependencies, build system, platform, or
  licensing require explicit maintainer approval.
- Discussion happens in the relevant GitHub issue or pull request so the record
  remains public where appropriate.
- When consensus is unclear, the maintainer makes the final decision and records
  the rationale.

Architectural invariants in [AGENTS.md](AGENTS.md) are settled policy until
changed through the governance amendment process. Design alternatives that were
evaluated are recorded under [Docs/Refactoring/](Docs/Refactoring/README.md).

## Quality gates

Changes to `main` are expected to pass:

1. `ruby -c core.rb`
2. `ruby scripts/check_core.rb`
3. `swiftc -typecheck -warnings-as-errors` for `metal/service.swift`
4. `python3 scripts/check_docs.py`
5. A manual launch for any shader, rendering, windowing, timing, or lifecycle
   change
6. Review of user-facing documentation and governance accuracy

`make check` runs the automated stages in order. Generated binaries under
`build/` are not committed to source control. There is no distribution artifact
today; any future packaging is produced only when the maintainer authorizes a
release.

## Releases

The project has no release yet. If versioning begins, releases follow semantic
versioning for the application and its public documentation.

A release requires the maintainer to:

1. confirm the checks and manual verification pass;
2. choose and document a version;
3. confirm README, governance, and origin records are current;
4. commit and tag the release if a tag is requested;
5. attach artifacts to a GitHub Release when distribution is intended; and
6. record notable changes and any compatibility notes.

No Git tag or public GitHub Release exists as part of the governance baseline.

## Licensing and intellectual property

- **No open-source license has been selected for this repository.** Absent a
  separate license, default copyright applies and no permission to reuse or
  redistribute is granted.
- The maintainer reserves all licensing decisions. A license must not be added,
  changed, or implied by an agent or contributor without explicit approval.
- All committed code must be original or properly licensed with attribution.
- AppKit, Metal, MetalKit, and QuartzCore are Apple frameworks used under the
  macOS SDK terms. The project does not redistribute SDK binaries or headers.
- This project is not affiliated with or endorsed by Apple.

See [Docs/PROJECT_ORIGIN.md](Docs/PROJECT_ORIGIN.md) for the commissioning record
and scope decisions.

## Security and privacy

The demonstration is local, has no accounts, and collects no telemetry. It stores
no preferences and writes no runtime data beyond the compiled service under
`build/`. Security handling is defined in [SECURITY.md](SECURITY.md).

## Repository and remote policy

- `origin` is the canonical GitHub remote over SSH:
  <git@github.com:dlcmh/ruby-core-with-metal-gui.git>
- `main` tracks `origin/main`.
- Force-pushing, rewriting published history, changing the canonical remote, or
  adding another release remote requires maintainer approval.
- Agents follow the commit and push rules in [AGENTS.md](AGENTS.md).

## Dependency policy

The accepted dependency baseline is **zero third-party dependencies**: the Ruby
standard library and the macOS AppKit, Metal, MetalKit, and QuartzCore frameworks
only. A proposed gem, Swift package, vendored source file, or build tool requires
maintainer approval and a review of its security, licensing, maintenance, and
binary-size impact.

Recorded alternatives are listed in
[Docs/Refactoring/README.md](Docs/Refactoring/README.md).

## Amendments

Governance changes are proposed as a pull request or explicit maintainer
instruction and require maintainer approval. The change should state why the
current rule is insufficient, what replaces it, and any migration impact.

The **Original request** quotation in
[Docs/PROJECT_ORIGIN.md](Docs/PROJECT_ORIGIN.md) is immutable. Historical
decisions may be annotated but must not be silently rewritten.

## Contact

Use the GitHub issue tracker for project questions and
[SECURITY.md](SECURITY.md) for vulnerabilities.
