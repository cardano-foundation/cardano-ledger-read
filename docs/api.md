# API Overview

This page provides an overview of the library's module structure
and main types.

## Conventions

Most component modules follow the same shape:

- an era-indexed wrapper type (e.g. `Inputs era`, `Outputs era`,
  `Fee era`), usually a `newtype` over a closed type family
  (`InputsType era`, `OutputsType era`, …) that selects the underlying
  `cardano-ledger` type per era;
- an accessor named `getEra<Component>` that projects that component out
  of a `Tx era` or `Block era` (e.g. `getEraInputs :: Tx era -> Inputs
  era`).

Era-polymorphic accessors carry an `IsEra era` constraint and dispatch
on the `Era` GADT singleton internally.

## Eras

Modules for handling Cardano's era system.

| Module | Description |
|--------|-------------|
| `Cardano.Read.Ledger.Eras` | Re-exports era types |
| `Cardano.Read.Ledger.Eras.KnownEras` | Era type-level list and constraints |
| `Cardano.Read.Ledger.Eras.EraValue` | Era-polymorphic value wrapper |

### EraValue

The `EraValue` type is an existential wrapper around an era-indexed
value `f era`, hiding the specific era behind an `IsEra` constraint:

```haskell
data EraValue f = forall era. IsEra era => EraValue (f era)
```

Pattern matching on `EraValue` brings the `IsEra` constraint back into
scope. Use `applyEraFun` to run an era-polymorphic function against the
wrapped value, `getEra` to recover the `Era` singleton, and
`eraValueSerialize` / `parseEraIndex` for the era-index serialization
prism. `fromConsensusBlock` is the typical source of an
`EraValue Block`.

## Blocks

Modules for reading block-level data.

| Module | Description |
|--------|-------------|
| `Cardano.Read.Ledger.Block.Block` | Block type and era extraction |
| `Cardano.Read.Ledger.Block.BHeader` | Block header access |
| `Cardano.Read.Ledger.Block.BlockNo` | Block number extraction |
| `Cardano.Read.Ledger.Block.SlotNo` | Slot number extraction |
| `Cardano.Read.Ledger.Block.HeaderHash` | Block header hash |
| `Cardano.Read.Ledger.Block.Txs` | Transaction list extraction |

## Transactions

Modules for reading transaction components.

### Core

| Module | Description |
|--------|-------------|
| `Cardano.Read.Ledger.Tx.Tx` | Transaction type |
| `Cardano.Read.Ledger.Tx.TxId` | Transaction ID |
| `Cardano.Read.Ledger.Tx.CBOR` | CBOR serialization |
| `Cardano.Read.Ledger.Tx.Eras` | Transaction era utilities |

### Inputs and Outputs

| Module | Description |
|--------|-------------|
| `Cardano.Read.Ledger.Tx.Inputs` | Transaction inputs |
| `Cardano.Read.Ledger.Tx.Outputs` | Transaction outputs |
| `Cardano.Read.Ledger.Tx.Output` | Single output type |
| `Cardano.Read.Ledger.Tx.CollateralInputs` | Collateral inputs (Alonzo+) |
| `Cardano.Read.Ledger.Tx.CollateralOutputs` | Collateral outputs (Babbage+) |
| `Cardano.Read.Ledger.Tx.ReferenceInputs` | Reference inputs (Babbage+) |

### Transaction Metadata

| Module | Description |
|--------|-------------|
| `Cardano.Read.Ledger.Tx.Fee` | Transaction fee |
| `Cardano.Read.Ledger.Tx.Validity` | Validity interval |
| `Cardano.Read.Ledger.Tx.Metadata` | Auxiliary metadata |
| `Cardano.Read.Ledger.Tx.Certificates` | Stake certificates |
| `Cardano.Read.Ledger.Tx.Withdrawals` | Stake withdrawals |
| `Cardano.Read.Ledger.Tx.Mint` | Token minting/burning |

### Scripts and Witnesses

| Module | Description |
|--------|-------------|
| `Cardano.Read.Ledger.Tx.Witnesses` | Transaction witnesses |
| `Cardano.Read.Ledger.Tx.ScriptValidity` | Script validation tag |
| `Cardano.Read.Ledger.Tx.Integrity` | Script integrity hash |
| `Cardano.Read.Ledger.Tx.ExtraSigs` | Required extra signers |

## Common Types

| Module | Description |
|--------|-------------|
| `Cardano.Read.Ledger.Address` | Address types |
| `Cardano.Read.Ledger.Value` | Multi-asset values |
| `Cardano.Read.Ledger.Hash` | Hash utilities |
| `Cardano.Read.Ledger.PParams` | Protocol parameters |

## Block generators

Helpers for constructing blocks in tests and benchmarks. These are
exposed but intended for testing rather than production reads.

| Module | Description |
|--------|-------------|
| `Cardano.Read.Ledger.Block.Gen` | `mkBlockEra` — build a `Block era` from `BlockParameters` |
| `Cardano.Read.Ledger.Block.Gen.BlockParameters` | `BlockParameters` (slot, block number, txs) |
| `Cardano.Read.Ledger.Block.Gen.Byron` | Byron block construction |
| `Cardano.Read.Ledger.Block.Gen.Shelley` | Shelley-family (TPraos) block construction |
| `Cardano.Read.Ledger.Block.Gen.Babbage` | Babbage-family (Praos) block construction |
