# cardano-ledger-read

[![CI](https://github.com/cardano-foundation/cardano-ledger-read/actions/workflows/CI.yaml/badge.svg)](https://github.com/cardano-foundation/cardano-ledger-read/actions/workflows/CI.yaml)
[![Docs](https://github.com/cardano-foundation/cardano-ledger-read/actions/workflows/deploy-docs.yaml/badge.svg)](https://github.com/cardano-foundation/cardano-ledger-read/actions/workflows/deploy-docs.yaml)

Era-indexed types for reading Cardano blockchain data.

[Documentation](https://cardano-foundation.github.io/cardano-ledger-read/)

## Overview

Data types and functions for blockchain data (blocks, transactions,
certificates, etc.) that are:

- Self-contained
- Compatible with [cardano-ledger](https://github.com/IntersectMBO/cardano-ledger) types
- Parameterized uniformly over the Cardano era (Byron, Shelley, Allegra, Mary, Alonzo, Babbage, Conway)
- Focused on reading from the blockchain

## Building

```bash
nix develop
just build
just test
```

## License

Apache-2.0
