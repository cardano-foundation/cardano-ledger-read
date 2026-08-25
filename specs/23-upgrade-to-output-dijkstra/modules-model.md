# Modules model — cardano-ledger-read#23

No new modules. No module is removed. No responsibility moves.

`Cardano.Read.Ledger.Tx.Output` remains the owner of era-indexed
transaction outputs and of the era-upgrade ladder
(`upgradeToOutputBabbage`, `upgradeToOutputConway`, and the new
`upgradeToOutputDijkstra`).

Do not promote a helper to a new module. Do not touch
`Cardano.Read.Ledger.Tx.Outputs` or any other module unless the
compiler reports a broken import from the one allowed file, which
is not expected.
