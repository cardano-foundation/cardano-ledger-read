# Tasks — cardano-ledger-read#21

Slice **S1** (OWNER). All tasks land in one PR.

- [x] **T001** `cabal.project`: both index-states (FR-INDEX) and the
      exact constraint block (FR-CONSTRAINTS). Old 11.0.1 values gone
      (INV-21-OLD-PINS-GONE).
- [x] **T002** `cardano-ledger-read.cabal` library `build-depends`:
      freeze-lower / next-minor-upper for every freeze-pinned
      package this library names (FR-BOUNDS).
- [x] **T003** `flake.nix` `indexState` → `2026-08-14T13:38:07Z`;
      `flake.lock` CHaP rev → `c0770200fcaa899ecdef548183dfee78e17bfb57`;
      `flake.lock` haskellNix `hackage` →
      `1d6c4337df9348ef6a1c21f7dfd47e9b9a454ccf` (Q-001 A).
- [x] **T004** Mechanical Haskell adaptation for consensus 4.x and
      crypto-class 2.5.x. Hard-stop on HS-DESIGN / HS-BEHAVIOUR /
      HS-OUTSIDE.
- [x] **T005** `fourmolu` check and `hlint` on touched Haskell
      sources.
- [x] **T006** `nix develop --quiet --accept-flake-config -c just build`
      and `just test` via the repo's own dev shell. Record any test
      failure with its cause.

Freeze provenance (control): sha256
`6a636c62ed1793c8dc8157633e1a907300efebdf9e98c4708cc8cbf8f317bab4`,
570 lines, copy at
`/tmp/projects/cardano-wallet/ms6-dijkstra/e-node-11-1-0/clr21/evidence/node-11.1.0-cabal.project.freeze`.
