{- |
Copyright: © 2020-2022 IOHK, 2024 Cardano Foundation
License: Apache-2.0

Era-dispatching block generation for testing and benchmarks.
-}
module Cardano.Read.Ledger.Block.Gen
    ( mkBlockEra
    ) where

import Prelude

import Cardano.Ledger.BaseTypes
    ( natVersion
    )
import Cardano.Read.Ledger.Block.Block
    ( Block (..)
    )
import Cardano.Read.Ledger.Block.Gen.Babbage
    ( mkBabbageBlock
    )
import Cardano.Read.Ledger.Block.Gen.BlockParameters
    ( BlockParameters (..)
    )
import Cardano.Read.Ledger.Block.Gen.Byron
    ( mkByronBlock
    )
import Cardano.Read.Ledger.Block.Gen.Shelley
    ( mkShelleyBlock
    )
import Cardano.Read.Ledger.Eras
    ( Era (..)
    , IsEra (..)
    )

{-# INLINEABLE mkBlockEra #-}

-- | Construct a block for any era from the given parameters.
mkBlockEra
    :: forall era. IsEra era => BlockParameters era -> Block era
mkBlockEra = case theEra @era of
    Byron -> g mkByronBlock
    Shelley -> g $ mkShelleyBlock (natVersion @2)
    Allegra -> g $ mkShelleyBlock (natVersion @3)
    Mary -> g $ mkShelleyBlock (natVersion @4)
    Alonzo -> g $ mkShelleyBlock (natVersion @6)
    Babbage -> g $ mkBabbageBlock (natVersion @7)
    Conway -> g $ mkBabbageBlock (natVersion @8)
    Dijkstra -> g $ mkBabbageBlock (natVersion @12)
  where
    g f = Block . f
