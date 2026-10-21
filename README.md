# Ruby Core · Metal

A deliberately small demonstration of a Ruby process supervising a native macOS
rendering service. The Ruby core owns the process lifecycle; a Swift + MetalKit
executable owns the window and draws one rotating square at 60 fps. There are no
gems, no Swift packages, no Xcode project, and no runtime assets.

Canonical source: <https://github.com/dlcmh/ruby-core-with-metal-gui>

## Requirements

- macOS 13 or newer on a Metal-capable Mac
- Xcode Command Line Tools, providing `swiftc`
- Ruby 2.6 or newer (the system Ruby is sufficient)

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

| Command | Effect |
| --- | --- |
| `ruby core.rb` | Build if needed, then launch at the default `0.9` rad/s |
| `ruby core.rb --speed 1.6` | Launch at the given finite angular velocity |
| `ruby core.rb --help` | Print usage without compiling or opening a window |

Invalid or missing speed values print usage to stderr and exit non-zero.

## Layout

```text
core.rb                 Ruby core: parses arguments, builds, launches, supervises
metal/service.swift     AppKit window, MetalKit view, Metal pipeline, embedded shaders
Docs/                   origin, design, Q&A, and decision records
scripts/                verification gate, CLI smoke checks, documentation checker
build/                  Generated binary and module cache (ignored by git)
AGENTS.md               Operating instructions for coding agents
CONTRIBUTING.md         Contribution workflow and quality bar
GOVERNANCE.md           Decision-making, release, and licensing policy
SECURITY.md             Vulnerability reporting and privacy posture
```

## How it works

1. [`core.rb`](core.rb) (`RubyMetalCore.run`) validates the command line, compiles
   the service when the source is newer than the binary, and starts it with
   `Process.spawn`.
2. The supervisor forwards `INT` and `TERM`, waits for the child, and exits with
   its status. Closing the window therefore ends both processes.
3. [`metal/service.swift`](metal/service.swift) (`Renderer`) creates an 800 × 600
   `NSWindow` backed by an `MTKView` and a single Metal render pipeline.
4. A four-vertex triangle strip is rotated by a uniform angle. The shader corrects
   for the drawable aspect ratio, so the square stays square when the window is
   resized.
5. The shader source is embedded as a Swift string and compiled by Metal at
   launch, so there are no `.metal` files or resource bundles.

The rotation integrates elapsed time with a clamped delta, so it does not depend
on the display refresh rate.

## Verify

```sh
make check
```

The gate runs:

1. `ruby -c core.rb`
2. `ruby scripts/check_core.rb` — CLI and failure-path smoke checks
3. `swiftc -typecheck -warnings-as-errors` for the service
4. `python3 scripts/check_docs.py` — links, anchors, and cited symbols

A typecheck cannot validate the shader because it compiles at runtime. After
changing shaders, rendering, windowing, timing, or lifecycle code, run
`ruby core.rb` and confirm the window appears, the square rotates, resizing keeps
it square, and closing the window returns to the prompt.

## Documentation

| Document | Purpose |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Operating rules and invariants for coding agents |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Build, verification, and contribution workflow |
| [GOVERNANCE.md](GOVERNANCE.md) | Decision-making, releases, and licensing |
| [SECURITY.md](SECURITY.md) | Vulnerability reporting and privacy posture |
| [Docs/PROJECT_ORIGIN.md](Docs/PROJECT_ORIGIN.md) | Commissioning record and scope decisions |
| [Docs/RUBY_METAL_DESIGN.md](Docs/RUBY_METAL_DESIGN.md) | Architecture and rationale |
| [Docs/QnA/README.md](Docs/QnA/README.md) | Focused implementation questions |
| [Docs/Refactoring/README.md](Docs/Refactoring/README.md) | Recorded design decisions |

Documentation cites files and symbols rather than line numbers. `make docs-check`
validates those references; `make docs-impact` lists the docs affected by the
current diff.

## License

No open-source license has been selected for this repository. Default copyright
applies; see [GOVERNANCE.md](GOVERNANCE.md). AppKit, Metal, MetalKit, and
QuartzCore are Apple frameworks used under the macOS SDK terms. This project is
not affiliated with or endorsed by Apple.
