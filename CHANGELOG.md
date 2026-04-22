# Changelog

## 1.0.0 (2026-04-22)


### Features

* add block generation modules and block-level tests ([7b6adf7](https://github.com/cardano-foundation/cardano-ledger-read/commit/7b6adf7cc7a55e8bf6cc591e915598660124b286)), closes [#5](https://github.com/cardano-foundation/cardano-ledger-read/issues/5)
* bump dependencies to cardano-node 10.6.2 and add Dijkstra era ([3c89471](https://github.com/cardano-foundation/cardano-ledger-read/commit/3c894717c2a9c97a2ecb98141644a8896e896e80)), closes [#3](https://github.com/cardano-foundation/cardano-ledger-read/issues/3)
* initial extraction of Cardano.Read.Ledger.* modules ([8ed86ac](https://github.com/cardano-foundation/cardano-ledger-read/commit/8ed86ac807017843d1f5943bd205df3a03693c34))
* update block generation for EraBlockBody API and add Dijkstra era ([3a95323](https://github.com/cardano-foundation/cardano-ledger-read/commit/3a953232fccb24a9a5c0a2c204dd652a2ba35714))


### Bug Fixes

* remove cabal-fmt (incompatible with GHC 9.12) ([053a026](https://github.com/cardano-foundation/cardano-ledger-read/commit/053a0260d6d740fa8a9a10cf5f303078cdd9a6f0))

## 0.1.0.0

* Initial release
* 34 era-indexed modules for reading Cardano blockchain data
* Supports all eras: Byron, Shelley, Allegra, Mary, Alonzo, Babbage, Conway
