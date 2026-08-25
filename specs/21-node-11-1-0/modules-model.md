# Modules model — cardano-ledger-read#21

No new modules. No module is removed. No responsibility moves.

Existing modules stay the nearest stable owners of their current
surfaces. Commit-owner edits are confined to:

- pin/lock/bounds files named in `plan.md`
- existing `src/` and `test/` modules only when the compiler
  reports a broken import, constructor, or type from
  `ouroboros-consensus` 4.x or `cardano-crypto-class` 2.5.x

Likely touch (lead, not a file list to hit): block/header/gen
modules that already import `Ouroboros.Consensus.*` or
`Cardano.Crypto.*`. Absence of a compiler error means do not touch
the file.

Do not promote any helper to a new module.
