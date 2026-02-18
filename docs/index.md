# cardano-ledger-read

!!! warning "Early Development"
    This library is in early development and is not production-ready.
    Use at your own risk.

`cardano-ledger-read` is a Haskell library for reading and interpreting
Cardano blockchain ledger data. It provides type-safe access to blocks,
transactions, and their components across all Cardano eras.

## Features

- **Era-polymorphic types** - Work with data from any Cardano era
  (Byron, Shelley, Allegra, Mary, Alonzo, Babbage, Conway)
- **Type-safe accessors** - Extract transaction components with
  compile-time guarantees
- **Minimal dependencies** - Built on top of `cardano-ledger` types

## Quick Start

Add to your `cabal` file:

```cabal
build-depends:
    cardano-ledger-read
```

## Example Usage

```haskell
import Cardano.Read.Ledger.Block.Block (getEraBlock)
import Cardano.Read.Ledger.Block.Txs (getEraTransactions)
import Cardano.Read.Ledger.Tx.Inputs (getInputs)
import Cardano.Read.Ledger.Tx.Outputs (getOutputs)

-- Extract transactions from a block
processBlock :: ConsensusBlock -> [EraTx]
processBlock block =
    case getEraBlock block of
        EraValue eraTxs -> getEraTransactions eraTxs
```

## Module Structure

The library is organized into three main areas:

- **Eras** - Era handling and polymorphic wrappers
- **Block** - Block-level data (headers, slot numbers, transactions)
- **Tx** - Transaction components (inputs, outputs, certificates, etc.)

See the [API Overview](api.md) for detailed module documentation.
