# shellcheck shell=bash

set unstable := true

# List available recipes
default:
    @just --list

# Format all source files
format:
    #!/usr/bin/env bash
    set -euo pipefail
    find src test -name '*.hs' -print0 | xargs -0 fourmolu -i
    # cabal-fmt doesn't support GHC 9.12 yet
    # cabal-fmt -i cardano-ledger-read.cabal
    nixfmt ./*.nix nix/*.nix

# Run hlint
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    find src test -name '*.hs' -print0 | xargs -0 hlint

# Build all components
build:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build all --enable-tests -O0

# Run tests
test:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal test all --enable-tests -O0

# Full CI pipeline
ci:
    #!/usr/bin/env bash
    set -euo pipefail
    just format
    just lint
    just build
    just test

# Serve docs locally
docs:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdocs serve

# Deploy docs to GitHub Pages
deploy-docs:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdocs gh-deploy --clean

# Clean build artifacts
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal clean
    rm -rf result site tmp
