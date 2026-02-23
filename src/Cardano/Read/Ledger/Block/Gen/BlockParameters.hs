{- |
Copyright: © 2024 Cardano Foundation
License: Apache-2.0

Parameters for generating blocks in any era.
-}
module Cardano.Read.Ledger.Block.Gen.BlockParameters
    ( BlockParameters (..)
    , exampleBlockParameters
    ) where

import Cardano.Read.Ledger.Block.BlockNo
    ( BlockNo (..)
    )
import Cardano.Read.Ledger.Block.SlotNo
    ( SlotNo (..)
    )
import Cardano.Read.Ledger.Tx.Tx
    ( Tx
    )

-- | Parameters for constructing a block in a specific era.
data BlockParameters era = BlockParameters
    { slotNumber :: SlotNo
    , blockNumber :: BlockNo
    , txs :: [Tx era]
    }

-- | Default block parameters with the given transactions.
exampleBlockParameters :: [Tx era] -> BlockParameters era
exampleBlockParameters txs =
    BlockParameters
        { slotNumber = SlotNo 0
        , blockNumber = BlockNo 0
        , txs
        }
