# Data model — cardano-ledger-read#23

No new types, fields, or state.

`OutputType Dijkstra = BabbageTxOut Dijkstra` and
`newtype Output era = Output (OutputType era)` already exist on
the base. The new function is an upgrade onto that existing type.

No validation rules change. No on-chain encoding is redesigned.
