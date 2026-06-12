# cardano-ledger-read

!!! warning "Early Development"
    This library is in early development and is not production-ready.
    Use at your own risk.

`cardano-ledger-read` is a Haskell library for reading and interpreting
Cardano blockchain ledger data. It provides era-indexed, type-safe
access to blocks, transactions, and their components across all Cardano
eras. The leaf types are the era-specific types from the
[`cardano-ledger`](https://github.com/IntersectMBO/cardano-ledger)
packages; this library adds a uniform era index on top of them.

It is a *read-side* projection layer: it reads and projects on-chain
data and deliberately does not construct, balance, sign, or submit
transactions.

## Features

- **Era-polymorphic types** — work with data from any known Cardano era
  (Byron, Shelley, Allegra, Mary, Alonzo, Babbage, Conway, Dijkstra)
- **Type-safe accessors** — extract block and transaction components
  with compile-time era guarantees
- **Thin projection** — built directly on `cardano-ledger` types, with a
  minimal dependency surface

## Quick Start

Depend on the package from your `cabal.project` (it is not yet on
Hackage or CHaP):

```cabal
source-repository-package
  type: git
  location: https://github.com/cardano-foundation/cardano-ledger-read
  tag: <commit-or-tag>
```

then add it to your package's `build-depends`:

```cabal
build-depends:
    cardano-ledger-read
```

## Example Usage

A block received from a node arrives as a `ConsensusBlock`, whose era is
not known statically. `fromConsensusBlock` recovers the era as an
`EraValue Block`, and `applyEraFun` runs an era-polymorphic accessor
against it:

```haskell
import Cardano.Read.Ledger.Block.Block (ConsensusBlock, fromConsensusBlock)
import Cardano.Read.Ledger.Block.Txs (getEraTransactions)
import Cardano.Read.Ledger.Eras.EraValue (applyEraFun)

-- | Number of transactions in a block, in any era.
txCount :: ConsensusBlock -> Int
txCount =
    applyEraFun (length . getEraTransactions) . fromConsensusBlock
```

When the era is known statically, work with `Tx era` directly — for
example, decode a transaction from CBOR with `deserializeTx` and read
its inputs:

```haskell
import Cardano.Read.Ledger.Tx.CBOR (deserializeTx)
import Cardano.Read.Ledger.Tx.Tx (Tx)
import Cardano.Read.Ledger.Tx.Inputs (Inputs, getEraInputs)
import Cardano.Read.Ledger.Eras (Conway)
import Cardano.Ledger.Binary (DecoderError)
import qualified Data.ByteString.Lazy as BL

conwayInputs :: BL.ByteString -> Either DecoderError (Inputs Conway)
conwayInputs cbor = do
    tx <- deserializeTx cbor :: Either DecoderError (Tx Conway)
    pure (getEraInputs tx)
```

## Module Structure

The library is organized into three main areas:

- **Eras** — era handling and polymorphic wrappers
- **Block** — block-level data (headers, slot numbers, transactions)
- **Tx** — transaction components (inputs, outputs, certificates, etc.)

See the [Architecture](architecture.md) page for the era model and the
[API Overview](api.md) for detailed module documentation.
