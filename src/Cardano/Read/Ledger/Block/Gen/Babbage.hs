{- |
Copyright: © 2020-2022 IOHK, 2024 Cardano Foundation
License: Apache-2.0

Block generation for Praos eras (Babbage, Conway).
-}
module Cardano.Read.Ledger.Block.Gen.Babbage
    ( mkBabbageBlock
    ) where

import Prelude

import Cardano.Crypto.DSIGN
    ( DSIGNAlgorithm (..)
    )
import Cardano.Crypto.Hash
    ( ByteString
    )
import Cardano.Crypto.VRF
    ( CertifiedVRF (CertifiedVRF)
    , VRFAlgorithm (..)
    )
import Cardano.Ledger.BaseTypes
    ( ProtVer (..)
    )
import Cardano.Ledger.Binary
    ( EncCBOR
    , Version
    )
import Cardano.Ledger.Keys
    ( VKey (..)
    )
import Cardano.Protocol.Crypto
    ( StandardCrypto
    )
import Cardano.Protocol.TPraos.BHeader
    ( PrevHash (..)
    )
import Cardano.Read.Ledger.Block.BlockNo
    ( BlockNo (..)
    )
import Cardano.Read.Ledger.Block.Gen.BlockParameters
    ( BlockParameters (..)
    )
import Cardano.Read.Ledger.Block.Gen.Shelley
    ( HeaderEra
    , bodyHash
    , hashHeader
    , mkAnyAfterShelleyBlock
    , mkKeyDSIGN'
    , mkKeyVRF'
    , mkSignedKES
    , oCertamente
    )
import Cardano.Read.Ledger.Block.SlotNo
    ( SlotNo (..)
    )
import Cardano.Read.Ledger.Tx.Tx
    ( TxT
    )
import Ouroboros.Consensus.Protocol.Praos
    ( Praos
    )
import Ouroboros.Consensus.Protocol.Praos.Header
    ( Header (..)
    , HeaderBody (..)
    )

import Cardano.Ledger.Core qualified as L
import Cardano.Ledger.Slot qualified as L
import Ouroboros.Consensus.Shelley.Ledger qualified as O

-- | Construct a block for a Praos era (Babbage, Conway).
mkBabbageBlock
    :: ( L.EraSegWits era
       , EncCBOR (HeaderEra era)
       , HeaderEra era ~ Header StandardCrypto
       , TxT cardano_era ~ L.Tx era
       )
    => Version
    -> BlockParameters cardano_era
    -> O.ShelleyBlock (Praos StandardCrypto) era
mkBabbageBlock v BlockParameters{blockNumber, slotNumber, txs} =
    mkAnyAfterShelleyBlock txs $ babbageHeader v slotNumber' blockNumber'
  where
    slotNumber' = L.SlotNo $ fromIntegral $ unSlotNo slotNumber
    blockNumber' = L.BlockNo $ fromIntegral $ unBlockNo blockNumber

babbageHeader
    :: Version
    -> L.SlotNo
    -> L.BlockNo
    -> Header StandardCrypto
babbageHeader v slotNumber blockNumber =
    Header <*> mkSignedKES $ babbageBody v slotNumber blockNumber

babbageBody
    :: Version -> L.SlotNo -> L.BlockNo -> HeaderBody StandardCrypto
babbageBody v slotNumber blockNumber =
    HeaderBody
        { hbBlockNo = blockNumber
        , hbSlotNo = slotNumber
        , hbPrev = BlockHash hashHeader
        , hbVk = VKey $ deriveVerKeyDSIGN mkKeyDSIGN'
        , hbVrfVk = deriveVerKeyVRF mkKeyVRF'
        , hbVrfRes =
            uncurry CertifiedVRF
                $ evalVRF () ("" :: ByteString) mkKeyVRF'
        , hbBodySize = 42
        , hbBodyHash = bodyHash
        , hbOCert = oCertamente
        , hbProtVer = ProtVer v 0
        }
