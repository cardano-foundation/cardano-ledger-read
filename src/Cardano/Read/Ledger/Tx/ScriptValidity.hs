{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

{- |
Copyright: © 2020-2022 IOHK
License: Apache-2.0

Raw mint data extraction from 'Tx'
-}
module Cardano.Read.Ledger.Tx.ScriptValidity
    ( -- * Script validity type
      ScriptValidityType
    , ScriptValidity (..)

      -- * Extraction
    , getEraScriptValidity
    ) where

import Prelude

import Cardano.Ledger.Alonzo.Tx
    ( IsPhase2Valid
    , isPhase2ValidTxL
    )
import Cardano.Read.Ledger.Eras
    ( Allegra
    , Alonzo
    , Babbage
    , Byron
    , Conway
    , Dijkstra
    , Era (..)
    , IsEra (..)
    , Mary
    , Shelley
    )
import Cardano.Read.Ledger.Tx.Eras
    ( onTx
    )
import Cardano.Read.Ledger.Tx.Tx
    ( Tx (..)
    )
import Control.Lens
    ( (^.)
    )

{- |
Era-specific script validity type.

Pre-Alonzo eras return unit @()@ as they lack Plutus scripts.
Alonzo and later return 'IsPhase2Valid' indicating script validation result.
-}
type family ScriptValidityType era where
    ScriptValidityType Byron = ()
    ScriptValidityType Shelley = ()
    ScriptValidityType Allegra = ()
    ScriptValidityType Mary = ()
    ScriptValidityType Alonzo = IsPhase2Valid
    ScriptValidityType Babbage = IsPhase2Valid
    ScriptValidityType Conway = IsPhase2Valid
    ScriptValidityType Dijkstra = IsPhase2Valid

-- | Era-indexed script validity tag wrapper.
newtype ScriptValidity era = ScriptValidity (ScriptValidityType era)

deriving instance
    Show (ScriptValidityType era) => Show (ScriptValidity era)
deriving instance
    Eq (ScriptValidityType era) => Eq (ScriptValidity era)

{-# INLINEABLE getEraScriptValidity #-}

-- | Extract the script validity tag from a transaction in any era.
getEraScriptValidity
    :: forall era. IsEra era => Tx era -> ScriptValidity era
getEraScriptValidity = case theEra @era of
    Byron -> \_ -> ScriptValidity ()
    Shelley -> \_ -> ScriptValidity ()
    Allegra -> \_ -> ScriptValidity ()
    Mary -> \_ -> ScriptValidity ()
    Alonzo -> alonzoScriptValidity
    Babbage -> alonzoScriptValidity
    Conway -> alonzoScriptValidity
    Dijkstra -> alonzoScriptValidity
  where
    alonzoScriptValidity = onTx $ \tx -> ScriptValidity $ tx ^. isPhase2ValidTxL
