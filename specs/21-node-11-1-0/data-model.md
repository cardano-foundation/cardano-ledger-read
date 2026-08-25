# Data model — cardano-ledger-read#21

No new types, fields, or state.

The library remains a read-side projection: era-indexed wrappers
over `cardano-ledger-*` types. The closed era list (Byron through
Dijkstra) does not change.

If an upstream type gains a required field whose value this library
would have to invent, that is **HS-DESIGN**: stop and file a Q.
A renamed field or moved constructor with a 1:1 replacement is
mechanical and in scope.

No validation rules change. No on-chain encoding is redesigned.
