#!/bin/sh
# Ruby Core · Metal verification gate.
#
# Run this before every commit, or simply `make check`.
#
# Stages:
#   1. ruby -c core.rb              supervisor syntax
#   2. ruby scripts/check_core.rb   CLI and failure-path smoke checks
#   3. swiftc -typecheck            service API and syntax, warnings denied
#   4. scripts/check_docs.py        links, anchors, and cited symbols
#
# The shell is POSIX so the gate works with /bin/sh. ruby, swiftc, python3, and
# the macOS SDK are the only requirements.

set -eu
cd "$(dirname "$0")/.."

RUBY="${RUBY:-ruby}"
SWIFTC="${SWIFTC:-swiftc}"
PYTHON="${PYTHON:-python3}"

main() {
    echo "==> ruby syntax"
    "$RUBY" -c core.rb >/dev/null

    echo "==> ruby CLI smoke checks"
    "$RUBY" scripts/check_core.rb

    echo "==> swift typecheck (warnings denied)"
    mkdir -p build/module-cache
    "$SWIFTC" -typecheck -warnings-as-errors \
        -module-cache-path build/module-cache \
        metal/service.swift \
        -framework AppKit \
        -framework Metal \
        -framework MetalKit \
        -framework QuartzCore

    echo "==> docs-check"
    "$PYTHON" scripts/check_docs.py

    echo "==> all checks passed"
}

main "$@"
