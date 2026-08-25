# Spec — cardano-ledger-read#21

Move this repository's hardcoded pin set from `cardano-node`
11.0.1 to 11.1.0. Source of every version: the node-11.1.0
`cabal.project.freeze` (commit `94ec4195f15f1fd290ab647be5e518b4e8b82e39`,
sha256 `6a636c62ed1793c8dc8157633e1a907300efebdf9e98c4708cc8cbf8f317bab4`,
570 lines). Resolver output. Do not improve versions from bounds.

Issue: https://github.com/cardano-foundation/cardano-ledger-read/issues/21

## User story

A downstream consumer aligned to `cardano-node` 11.1.0 can take this
package as a `source-repository-package` without fighting 11.0.1
index-states or constraints.

## Functional requirements

- **FR-INDEX.** Both `cabal.project` index-state occurrences become
  hackage `2026-08-14T13:38:07Z` and CHaP `2026-08-17T11:39:16Z`.
- **FR-CONSTRAINTS.** The `constraints:` block becomes exactly:

  ```cabal
  constraints:
      cardano-ledger-allegra ==1.10.0.0
    , cardano-ledger-alonzo ==1.16.0.0
    , cardano-ledger-api ==1.14.0.0
    , cardano-ledger-babbage ==1.14.0.0
    , cardano-ledger-byron ==1.3.0.0
    , cardano-ledger-conway ==1.23.0.0
    , cardano-ledger-core ==1.21.0.0
    , cardano-ledger-mary ==1.11.0.0
    , cardano-ledger-shelley ==1.19.0.0
    , ouroboros-consensus ==4.1.0.0
    , cardano-crypto-class ==2.5.1.0
    , cardano-crypto-praos ==2.2.4.0
    , cardano-protocol-tpraos ==1.6.0.0
  ```

  Only `cardano-ledger-byron` is unchanged. Do not add or drop
  packages in this block.
- **FR-BOUNDS.** For every freeze-pinned package named in
  `cardano-ledger-read.cabal` library `build-depends`, lower bound is
  the freeze version and upper bound is the next minor
  (`cardano-deps` bound format).
- **FR-CHAP.** `flake.lock` CHaP `locked.rev` equals node 11.1.0's
  CHaP rev `c0770200fcaa899ecdef548183dfee78e17bfb57`.
- **FR-NIX-INDEX.** `flake.nix` `indexState` equals the hackage
  index-state `2026-08-14T13:38:07Z`.
- **FR-BUILD.** The project builds in this repo's own
  `nix develop` shell (`just build`).
- **FR-TEST.** `just test` passes, or each failure is recorded with
  its cause. Failures are not silently ignored.
- **FR-ADAPT.** Source edits are only the mechanical API adaptations
  the two majors force (`ouroboros-consensus` 3→4,
  `cardano-crypto-class` 2.3→2.5). Same PR as the pin set.
- **FR-FORMAT.** `fourmolu` check and `hlint` clean on touched
  Haskell sources.

## Hard stops (file Q, park, do not improvise)

- **HS-DESIGN.** An API change requires a design decision (new
  fields whose values would have to be invented), not a mechanical
  rename/import/type-hole fill.
- **HS-BEHAVIOUR.** The build cannot pass without changing
  observable behaviour.
- **HS-OUTSIDE.** Adaptation would require touching anything
  outside this repository.

## Rejection

- Invented versions, bound-arithmetic "improvements", extra
  constraint-block members, coverage expansion, refactors, new test
  suites, behaviour changes, or work outside this repo.

## Invariants

| ID | Severity | Observable truth |
|---|---|---|
| INV-21-INDEX-STATE | BLOCKING | Both index-state lines match FR-INDEX. |
| INV-21-CONSTRAINTS | BLOCKING | Constraint block byte-equal to FR-CONSTRAINTS (whitespace-normalized). |
| INV-21-BOUNDS | BLOCKING | Library deps named in the freeze have freeze-lower / next-minor-upper. |
| INV-21-CHAP | BLOCKING | `flake.lock` CHaP rev is `c0770200fcaa899ecdef548183dfee78e17bfb57`. |
| INV-21-NIX-INDEX | BLOCKING | `flake.nix` `indexState` is `2026-08-14T13:38:07Z`. |
| INV-21-BUILD | BLOCKING | `nix develop --quiet --accept-flake-config -c just build` exits 0. |
| INV-21-TEST | BLOCKING | `nix develop --quiet --accept-flake-config -c just test` exits 0, or each failure is recorded with cause in the receipt. |
| INV-21-ADAPT-MECHANICAL | BLOCKING | Every `.hs` hunk is a compiler-forced mechanical adaptation; no invented fields. |
| INV-21-NO-OUTSIDE | BLOCKING | Diff paths stay inside this repository. |
| INV-21-OLD-PINS-GONE | BLOCKING | 11.0.1 values (`ouroboros-consensus ==3.0.1.0`, `cardano-crypto-class ==2.3.2.0`, hackage index-state `2026-03-26T20:21:33Z`) are absent from `cabal.project`. |

Severity BLOCKING here is ticket-acceptance: a wrong pin is the
defect. None of these values is chain state, money, or a signature
produced by this library (read-side only). Auditor mutation campaigns
are **forbidden** on this ticket (operator: sanity checks only).

## Acceptance

1. FR-INDEX through FR-FORMAT hold.
2. Hard stops were either unused or filed as Q and parked.
3. Every absence claim is paired with a positive control (method
   shown to find something known to be present).
