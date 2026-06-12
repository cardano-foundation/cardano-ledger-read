---
name: cardano-ledger-read-guide
description: >-
  Guide for working in the cardano-foundation/cardano-ledger-read Haskell
  library: era-indexed types and accessors for READING Cardano on-chain
  data (blocks, transactions, inputs, outputs, fees, certificates,
  metadata, mint, withdrawals, witnesses). Load when a task mentions
  cardano-ledger-read, the module prefix Cardano.Read.Ledger, the era
  model (KnownEras, Era GADT, IsEra, theEra, EraValue, applyEraFun,
  fromConsensusBlock, ConsensusBlock), accessors named getEra* (e.g.
  getEraInputs, getEraOutputs, getEraTransactions, getEraBHeader,
  getEraTxHash), CBOR (serializeTx, deserializeTx), the closed-world era
  list (Byron Shelley Allegra Mary Alonzo Babbage Conway Dijkstra), or the
  build via nix develop + just (just build, just test, just ci) with
  GHC 9.12 / haskell.nix / CHaP. Use it to navigate the code, build and
  test, write era-polymorphic reads, or answer questions about the library.
---

# cardano-ledger-read guide

`cardano-ledger-read` is a read-only projection layer over the
`cardano-ledger-*` packages. It gives every on-chain concept a uniform
era index and accessors to read it. It does **not** build, balance,
sign, or submit transactions.

## Repository map

| Path | Purpose |
|------|---------|
| `src/Cardano/Read/Ledger/Eras/KnownEras.hs` | `KnownEras` type-level list, `Era` GADT singleton, `IsEra`/`theEra`, era aliases, `indexOfEra` |
| `src/Cardano/Read/Ledger/Eras/EraValue.hs` | `EraValue` existential, `applyEraFun`, `applyEraFunValue`, `getEra`, `parseEraIndex`, `eraValueSerialize` |
| `src/Cardano/Read/Ledger/Eras.hs` | Re-exports `KnownEras` |
| `src/Cardano/Read/Ledger/Block/Block.hs` | `ConsensusBlock`, `Block` newtype, `fromConsensusBlock`, `toConsensusBlock` |
| `src/Cardano/Read/Ledger/Block/BHeader.hs` | `BHeader`, `getEraBHeader` |
| `src/Cardano/Read/Ledger/Block/BlockNo.hs` | `BlockNo`, `getEraBlockNo`, `prettyBlockNo` |
| `src/Cardano/Read/Ledger/Block/SlotNo.hs` | `SlotNo`, `getEraSlotNo`, `from/toLedgerSlotNo`, `prettySlotNo` |
| `src/Cardano/Read/Ledger/Block/HeaderHash.hs` | `getEraHeaderHash`, `getRawHeaderHash`, `getEraPrevHeaderHash` |
| `src/Cardano/Read/Ledger/Block/Txs.hs` | `getEraTransactions :: Block era -> [Tx era]` |
| `src/Cardano/Read/Ledger/Block/Gen/` | Test block generators (`mkBlockEra`, `BlockParameters`) |
| `src/Cardano/Read/Ledger/Tx/Tx.hs` | `Tx` newtype, `TxT` type family |
| `src/Cardano/Read/Ledger/Tx/*` | Per-component accessors (see below) |
| `src/Cardano/Read/Ledger/{Address,Value,Hash,PParams}.hs` | Common types |
| `test/` | hspec unit tests + per-era example transactions |
| `docs/` | mkdocs site (`index.md`, `architecture.md`, `api.md`) |
| `.specify/memory/constitution.md` | Binding architectural rules |

The `Tx/*` accessor modules each export an era-indexed `newtype` wrapper
and a `getEra<Component>` function: `Inputs`/`getEraInputs`,
`Outputs`/`getEraOutputs`, `Output`/`getEraValue`,
`CollateralInputs`/`getEraCollateralInputs`,
`CollateralOutputs`/`getEraCollateralOutputs`,
`ReferenceInputs`/`getEraReferenceInputs`, `Fee`/`getEraFee`,
`Validity`/`getEraValidity`, `Metadata`/`getEraMetadata`,
`Certificates`/`getEraCertificates`, `Withdrawals`/`getEraWithdrawals`,
`Mint`/`getEraMint`, `Witnesses`/`getEraWitnesses`,
`ScriptValidity`/`getEraScriptValidity`, `Integrity`/`getEraIntegrity`,
`ExtraSigs`/`getEraExtraSigs`, `TxId`/`getEraTxId`. CBOR lives in
`Tx/CBOR.hs` (`serializeTx`, `deserializeTx`); `Tx/Hash.hs` has
`getEraTxHash`; `Tx/Eras.hs` has the `onTx` helper.

## Build, test, run

Everything runs in the Nix dev shell. Prefer `just` recipes:

```bash
nix develop                 # haskell.nix shell: cabal, GHC 9.12, just
just build                  # cabal build all --enable-tests -O0
just test                   # cabal test all --enable-tests -O0
just format                 # fourmolu + nixfmt
just lint                   # hlint
just ci                     # format + lint + build + test
nix run .#cardano-ledger-read-tests   # what CI runs for the test job
nix develop .#docs --command mkdocs build --strict   # build docs like CI
```

There is no executable; the only build artifact is the library and its
`unit-tests` suite.

## Navigating the code

- Start from the era model: `Eras/KnownEras.hs` (the closed era list and
  singleton) and `Eras/EraValue.hs` (the runtime-era existential).
- Reading entry point: `fromConsensusBlock` in `Block/Block.hs` turns a
  node's `ConsensusBlock` into an `EraValue Block`.
- To find how a component is read, open `Tx/<Component>.hs`; each is a
  small module: a `type family <Component>Type era`, a `newtype` wrapper,
  and a `getEra<Component>` that does `case theEra @era of …`.
- Every era-dispatching `case` enumerates all eras with no wildcard — to
  see era coverage, grep for `Dijkstra ->` or `case theEra`.
- Tests in `test/Test/Unit/Cardano/Read/Ledger/` show real usage and
  carry per-era CBOR example transactions (`byronTx` … `dijkstraTx`).

## Using the library

Read a block whose era is unknown (e.g. from a node):

```haskell
import Cardano.Read.Ledger.Block.Block (ConsensusBlock, fromConsensusBlock)
import Cardano.Read.Ledger.Block.Txs (getEraTransactions)
import Cardano.Read.Ledger.Tx.Hash (getEraTxHash)
import Cardano.Read.Ledger.Eras.EraValue (applyEraFun)
import Data.ByteString (ByteString)

txCount :: ConsensusBlock -> Int
txCount = applyEraFun (length . getEraTransactions) . fromConsensusBlock

txHashes :: ConsensusBlock -> [ByteString]
txHashes =
    applyEraFun (map getEraTxHash . getEraTransactions)
        . fromConsensusBlock
```

Decode a transaction at a known era and read its components:

```haskell
import Cardano.Read.Ledger.Tx.CBOR (deserializeTx)
import Cardano.Read.Ledger.Tx.Tx (Tx)
import Cardano.Read.Ledger.Tx.Inputs (Inputs, getEraInputs)
import Cardano.Read.Ledger.Tx.Outputs (Outputs, getEraOutputs)
import Cardano.Read.Ledger.Eras (Conway)
import Cardano.Ledger.Binary (DecoderError)
import qualified Data.ByteString.Lazy as BL

readConway
    :: BL.ByteString
    -> Either DecoderError (Inputs Conway, Outputs Conway)
readConway cbor = do
    tx <- deserializeTx cbor :: Either DecoderError (Tx Conway)
    pure (getEraInputs tx, getEraOutputs tx)
```

Key facts to keep correct:

- The accessor naming is `getEra<Component>`. There is no `getInputs`,
  `getOutputs`, or `getEraBlock` — use `getEraInputs`, `getEraOutputs`,
  and `fromConsensusBlock`.
- `EraValue` is an existential (`forall era. IsEra era => EraValue (f
  era)`), not a GADT-syntax declaration. Consume it with `applyEraFun`.
- Component wrapper types are `newtype`s over a type family, not
  `Foldable` — unwrap before using `length`/`toList`.

## Answering questions

- "What is this / what does it do?" — README **What is this**; one-line
  summary in `cardano-ledger-read.cabal` (`synopsis`/`description`).
- "Which eras are supported?" — `Eras/KnownEras.hs` (`KnownEras`):
  Byron, Shelley, Allegra, Mary, Alonzo, Babbage, Conway, Dijkstra.
- "How do I read X from a transaction?" — the `Tx/X.hs` module's
  `getEraX`; full map in `docs/api.md`.
- "How do I read a block from a node?" — `fromConsensusBlock` +
  `applyEraFun`; see README **Usage** and `docs/index.md`.
- "How is the era polymorphism built?" — `docs/architecture.md` and
  `.specify/memory/constitution.md` (closed-world eras, type families +
  GADT dispatch, `EraValue`).
- "How do I build / test?" — README **Development**; `justfile`;
  `.github/workflows/CI.yaml`.
- "Can it build/sign/submit transactions?" — No. It is read-only by
  design (constitution, principle I).
