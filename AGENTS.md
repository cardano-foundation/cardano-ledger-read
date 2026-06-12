# Repository Agent Guide

## What this repo is

`cardano-ledger-read` is a Haskell library of era-indexed types and
accessors for **reading** Cardano on-chain data — blocks, transactions,
and their components (inputs, outputs, fees, certificates, metadata, …).
The leaf types are the era-specific types from the `cardano-ledger-*`
packages; this library adds a uniform era index (`KnownEras`, the `Era`
GADT singleton, the `IsEra` class, and the `EraValue` existential) on
top of them. It is a read-side projection layer only: it does not
construct, balance, sign, or submit transactions.

The supported eras are a closed list: Byron, Shelley, Allegra, Mary,
Alonzo, Babbage, Conway, Dijkstra.

## How to work here

All commands run inside the Nix dev shell (`nix develop`, or `direnv`
with `use flake`). Use the `just` recipes rather than raw cabal/nix:

- Build: `just build` (`cabal build all --enable-tests -O0`)
- Test: `just test` (`cabal test all --enable-tests -O0`)
- Format: `just format` (fourmolu + nixfmt)
- Lint: `just lint` (hlint)
- Full local CI: `just ci` (format + lint + build + test)
- Serve docs: `just docs` (mkdocs serve)
- Build docs like CI: `nix develop .#docs --command mkdocs build --strict`

The compiler is GHC 9.12 via `haskell.nix`; dependencies resolve from
CHaP (see `cabal.project` for index-state and version constraints).
CI (`.github/workflows/CI.yaml`) runs `nix run .#cardano-ledger-read-tests`
and the `.#quality` shell's format + lint.

## Repository layout

- `src/Cardano/Read/Ledger/` — the library:
  - `Eras/` — era model (`KnownEras`, `EraValue`).
  - `Block/` — block, header, slot/block number, header hash, txs; plus
    `Block/Gen/` test block generators.
  - `Tx/` — transaction type and per-component accessors.
  - `Address`, `Value`, `Hash`, `PParams` — common types.
- `test/` — hspec unit tests with per-era example transactions.
- `docs/` — mkdocs site (`index.md`, `architecture.md`, `api.md`).
- `.specify/memory/constitution.md` — the binding architectural rules.

## Conventions

- Era-indexed component modules export a `newtype` wrapper over a closed
  type family (`InputsType era`, `OutputsType era`, …) and a
  `getEra<Component>` accessor (`getEraInputs`, `getEraOutputs`, …).
- Era-polymorphic operations carry an `IsEra era` constraint and
  `case theEra @era of …` over every era — no wildcard branch.
- Adding/removing an era is a closed-world sweep; see the constitution.

## Skills

Activatable procedures live under `skills/`. Load the one whose
description matches your task:

- `skills/cardano-ledger-read-guide/` — how to navigate this codebase,
  build/test it, use the era model and accessors, and answer common
  questions about the library.
