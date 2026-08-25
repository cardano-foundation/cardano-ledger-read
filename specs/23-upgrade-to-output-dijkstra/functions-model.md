# Functions model — cardano-ledger-read#23

New export, same module:

- name: `upgradeToOutputDijkstra`
- arguments: implicit `IsEra era`; value `Output era`
- result: `Output Dijkstra`
- constraint: total; no `error`; Dijkstra case is identity
- effects: none

Unchanged (do not edit):

- `upgradeToOutputBabbage`
  :: `IsEra era => Output era -> Maybe (Output Babbage)`
- `upgradeToOutputConway`
  :: `IsEra era => Output era -> Output Conway`

Inventing a different result type (`Maybe`, `Either`, or a
downgrade `error`) is **HS-ERROR** / **HS-ORDER**.
