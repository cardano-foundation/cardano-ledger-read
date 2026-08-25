# Spec — cardano-ledger-read#23

Add `upgradeToOutputDijkstra`, completing the era-upgrade ladder
for the Dijkstra hard fork.

Issue: https://github.com/cardano-foundation/cardano-ledger-read/issues/23

Base: `d5847e29f5f9633fad268c0debd1413c353e5523` (`origin/main`,
#22). Types for Dijkstra are already in this tree.

## User story

A reader holding an `Output era` can upgrade it to
`Output Dijkstra`. Downstream (`cardano-wallet` `toConwayOutput`)
already consumes the Conway rung; the Dijkstra rung must exist in
this library before a `toDijkstraOutput` can.

## Functional requirements

- **FR-EXPORT.** `src/Cardano/Read/Ledger/Tx/Output.hs` exports
  `upgradeToOutputDijkstra`.
- **FR-SIG.** Signature is
  `upgradeToOutputDijkstra :: forall era. IsEra era => Output era -> Output Dijkstra`.
- **FR-SHAPE.** Follow `upgradeToOutputConway`: every earlier era
  upgrades toward Dijkstra; `Dijkstra` is identity.
- **FR-NO-ERROR.** The new function has no `error` branch. There is
  no impossible case. Writing one is a stop condition, not a fix.
- **FR-CONWAY.** `upgradeToOutputConway` is unchanged, including
  `Dijkstra -> error "upgradeToOutputConway: cannot downgrade from Dijkstra"`.
  That line is a genuine downgrade, not a stub.
- **FR-PARITY.** This repository has **no** unit test naming
  `upgradeToOutputBabbage` or `upgradeToOutputConway` (control:
  `rg upgradeToOutput test/` is empty; same method finds 9 hits in
  `src/`). Do not add a test suite. Existing `just test` is the
  coverage bar. The wallet `OutputSpec.hs` Conway-pointer test is
  not this ticket's bar and is not to be copied.
- **FR-BUILD.** `nix develop --quiet --accept-flake-config
  --no-write-lock-file -c just build` succeeds.
- **FR-TEST.** `just test` in the same shell passes.
- **FR-FORMAT.** `fourmolu -m check` and `hlint` clean on touched
  Haskell.

## Hard stops (file Q, park, do not improvise)

- **HS-ERROR.** The new function appears to need an `error` branch.
- **HS-ORDER.** Era ordering does not behave as this spec describes.
- **HS-API.** `cardano-ledger-dijkstra` 0.3.0.0 does not expose
  `upgradeTxOut` (or equivalent) for Conway → Dijkstra.
- **HS-OUTSIDE.** The change cannot be made without touching another
  repository.

## Rejection

- Editing `upgradeToOutputConway` (including removing its Dijkstra
  `error`).
- A new test suite or coverage expansion beyond sibling parity.
- Pin/lock/bounds edits, refactors, work outside this clone.
- Tracked `.gitignore` changes (`/gate.sh` and `.orch/` belong in
  `.git/info/exclude`).

## Invariants

| ID | Severity | Observable truth |
|---|---|---|
| INV-23-EXPORT | ADVISORY | The module export list names `upgradeToOutputDijkstra`. |
| INV-23-SIG | ADVISORY | The exported type is FR-SIG. |
| INV-23-NO-ERROR | ADVISORY | The new function body contains no `error`. |
| INV-23-IDENTITY | ADVISORY | The Dijkstra case of the new function is identity. |
| INV-23-CONWAY | ADVISORY | Conway's Dijkstra line is the exact current error string. |
| INV-23-PARITY | ADVISORY | No new test suite; existing tests still pass. |
| INV-23-BUILD | ADVISORY | `just build` in the repo dev shell exits 0. |
| INV-23-TEST | ADVISORY | `just test` in the repo dev shell exits 0. |

Read-side library; values do not reach chain state, money, or a
signature from this package. Severity is ADVISORY. The gate still
enforces every row.

## Absence claims and controls

- Missing Dijkstra rung: `rg upgradeToOutputDijkstra src/` is empty
  on the base; same command finds `upgradeToOutputConway` (9
  `upgradeToOutput` hits in `src/`).
- Sibling test coverage is zero in this repo: `rg upgradeToOutput
  test/` empty; control is the 9 src hits.
- No other `upgradeTo*` ladder exists in `src/` (control: the same
  `rg upgradeTo` returns only the Output.hs Babbage/Conway pair).
  Report, do not silently add, any further missing rung found while
  touching this file.
