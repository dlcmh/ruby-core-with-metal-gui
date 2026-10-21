# How does the Ruby core supervise the Metal service?

- **Recorded:** 2026-10-21
- **Last updated:** 2026-10-21

The supervisor is a small state machine with four steps: parse, build if needed,
spawn, wait. All of it lives in [`core.rb`](../../core.rb) (`RubyMetalCore.run`).

## 1. Parse arguments

[`core.rb`](../../core.rb) (`RubyMetalCore.parse_args`) handles `--help`/`-h` and
`--speed`. A speed is accepted only when `Float` produces a finite number; `NaN`
and `Infinity` parse as floats but fail the `finite?` check. Invalid input aborts
with usage on stderr and a non-zero status. Help exits zero before any build.

The default is `DEFAULT_SPEED`, `0.9` radians per second.

## 2. Build when stale

[`core.rb`](../../core.rb) (`RubyMetalCore.compile_service`) compares the modification
time of `SOURCE` (`metal/service.swift`) with `BINARY`
(`build/metal-service`). If the binary is missing or older, it creates `build/` and
runs `swiftc -O` with the four required frameworks.

The command is an argument array passed to `system`, so no shell interprets the
paths. A failure calls `abort`, which exits non-zero with a `[core]` message.

## 3. Spawn

[`core.rb`](../../core.rb) (`RubyMetalCore.run`) calls `Process.spawn(BINARY, "--speed",
speed.to_s)`. The service inherits stdio, so its `[metal-service]` diagnostics
appear in the same terminal. No pipe is created and no output is parsed.

## 4. Forward signals and wait

The supervisor installs traps for `INT` and `TERM`. Each trap forwards the same
signal to the child and ignores `Errno::ESRCH`, which means the child already
exited. It then calls `Process.wait2` and exits with the child's status, or
`128 + signal` when the child was terminated by a signal.

Closing the window makes the service terminate normally; that unblocks the wait and
the supervisor exits with the same status. Ctrl-C in the terminal sends `INT` to
Ruby, which forwards it to the service.

## What the supervisor deliberately does not do

- It does not render, create windows, or touch Metal.
- It does not restart the service, buffer its output, or supervise a health check.
- It does not use a shell, a temporary script, or environment mutation.

Those omissions keep the process contract small enough to describe in one
paragraph. Adding a restart policy or a message channel would change that
contract; see [../RUBY_METAL_DESIGN.md](../RUBY_METAL_DESIGN.md#2-the-process-contract).
