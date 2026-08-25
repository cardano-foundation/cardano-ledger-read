# Tasks — cardano-ledger-read#23

Slice **S1** (OWNER). All tasks land in one PR.

- [ ] **T001** Export and implement `upgradeToOutputDijkstra`
      (FR-EXPORT, FR-SIG, FR-SHAPE, FR-NO-ERROR). Haddock matching
      the Conway sibling. Do not edit `upgradeToOutputConway`
      (FR-CONWAY).
- [ ] **T002** `fourmolu -m check` and `hlint` on touched Haskell
      (FR-FORMAT).
- [ ] **T003** `just build` and `just test` via the repo's own
      `nix develop` (FR-BUILD, FR-TEST).
- [ ] **T004** Test coverage at sibling parity: no new test suite
      (FR-PARITY). Existing tests still pass.

Control for T004: on the base, `rg upgradeToOutput test/` is empty
and `rg upgradeToOutput src/` has 9 hits.
