{-# OPTIONS_GHC -Wno-orphans #-}

{- |
Copyright: © 2020-2022 IOHK, 2024 Cardano Foundation
License: Apache-2.0

Block generation for TPraos eras (Shelley, Allegra, Mary, Alonzo).
-}
module Cardano.Read.Ledger.Block.Gen.Shelley
    ( -- * Block construction
      mkShelleyBlock
    , mkAnyAfterShelleyBlock

      -- * Header era type family
    , HeaderEra

      -- * Crypto helpers
    , bodyHash
    , hashHeader
    , mkKeyDSIGN'
    , mkKeyKES'
    , mkKeyVRF'
    , mkSignedKES
    , oCertamente
    ) where

import Prelude

import Cardano.Crypto.DSIGN
    ( DSIGNAlgorithm (..)
    , Ed25519DSIGN
    , signedDSIGN
    )
import Cardano.Crypto.Hash
    ( ByteString
    )
import Cardano.Crypto.KES
    ( UnsoundPureKESAlgorithm (..)
    , UnsoundPureSignKeyKES
    , signKeySizeKES
    , unsoundPureSignedKES
    )
import Cardano.Crypto.Seed
    ( mkSeedFromBytes
    )
import Cardano.Crypto.Util
    ( SignableRepresentation
    )
import Cardano.Crypto.VRF
    ( CertifiedVRF (CertifiedVRF)
    , VRFAlgorithm (..)
    )
import Cardano.Crypto.VRF.Praos
    ( PraosVRF
    )
import Cardano.Ledger.BaseTypes
    ( ProtVer (..)
    , Version
    )
import Cardano.Ledger.Block
    ( Block (..)
    )
import Cardano.Ledger.Keys
    ( VKey (..)
    )
import Cardano.Protocol.Crypto
    ( StandardCrypto
    )
import Cardano.Protocol.TPraos.BHeader
    ( BHBody (..)
    , BHeader (..)
    , HashHeader (..)
    , PrevHash (..)
    )
import Cardano.Protocol.TPraos.OCert
    ( KESPeriod (..)
    , OCert (..)
    , OCertSignable (OCertSignable)
    )
import Cardano.Read.Ledger.Block.BlockNo
    ( BlockNo (..)
    )
import Cardano.Read.Ledger.Block.Gen.BlockParameters
    ( BlockParameters (..)
    )
import Cardano.Read.Ledger.Block.SlotNo
    ( SlotNo (..)
    )
import Cardano.Read.Ledger.Tx.Tx
    ( Tx
    , TxT
    , unTx
    )
import Control.Lens
    ( (&)
    , (.~)
    )
import Data.Proxy
    ( Proxy (..)
    )
import Ouroboros.Consensus.Protocol.Praos.Header
    ( Header (..)
    )
import Ouroboros.Consensus.Protocol.TPraos
    ( TPraos
    )

import Cardano.Crypto.DSIGN qualified as Crypto
import Cardano.Crypto.Hash qualified as Crypto
import Cardano.Crypto.KES qualified as Crypto
import Cardano.Ledger.Api qualified as L
import Cardano.Ledger.Block qualified as L
import Cardano.Ledger.Core qualified as L
import Cardano.Ledger.Slot qualified as L
import Data.ByteString.Char8 qualified as B8
import Data.ByteString.Short qualified as BS
import Data.Sequence.Strict qualified as Seq
import Ouroboros.Consensus.Shelley.Ledger qualified as O
import Ouroboros.Consensus.Shelley.Protocol.Abstract qualified as O

-- | Mapping from ledger eras to their consensus header types.
type family HeaderEra era where
    HeaderEra L.ShelleyEra = BHeader StandardCrypto
    HeaderEra L.AllegraEra = BHeader StandardCrypto
    HeaderEra L.MaryEra = BHeader StandardCrypto
    HeaderEra L.AlonzoEra = BHeader StandardCrypto
    HeaderEra L.BabbageEra = Header StandardCrypto
    HeaderEra L.ConwayEra = Header StandardCrypto
    HeaderEra L.DijkstraEra = Header StandardCrypto

--------------------------------------------------------------------------------
-- Valid for Shelley, Allegra, Mary, Alonzo
--------------------------------------------------------------------------------

hbody :: Version -> L.SlotNo -> L.BlockNo -> BHBody StandardCrypto
hbody v slotNumber blockNumber =
    BHBody
        { bheaderBlockNo = blockNumber
        , bheaderSlotNo = slotNumber
        , bheaderPrev = BlockHash hashHeader
        , bheaderVk = VKey $ deriveVerKeyDSIGN mkKeyDSIGN'
        , bheaderVrfVk = deriveVerKeyVRF mkKeyVRF'
        , bheaderEta =
            uncurry CertifiedVRF
                $ evalVRF () ("" :: ByteString) mkKeyVRF'
        , bheaderL =
            uncurry CertifiedVRF
                $ evalVRF () ("" :: ByteString) mkKeyVRF'
        , bsize = 42
        , bhash = bodyHash
        , bheaderOCert = oCertamente
        , bprotver = ProtVer v 0
        }

headerShelley
    :: Version
    -> L.SlotNo
    -> L.BlockNo
    -> BHeader StandardCrypto
headerShelley v slotNumber blockNumber =
    BHeader <*> mkSignedKES $ hbody v slotNumber blockNumber

-- | Construct a block for a TPraos era (Shelley, Allegra, Mary, Alonzo).
mkShelleyBlock
    :: ( L.EraBlockBody era
       , HeaderEra era ~ BHeader StandardCrypto
       , TxT cardano_era ~ L.Tx L.TopTx era
       )
    => Version
    -> BlockParameters cardano_era
    -> O.ShelleyBlock (TPraos StandardCrypto) era
mkShelleyBlock v BlockParameters{blockNumber, slotNumber, txs} =
    mkAnyAfterShelleyBlock txs $ headerShelley v slotNumber' blockNumber'
  where
    slotNumber' = L.SlotNo $ fromIntegral $ unSlotNo slotNumber
    blockNumber' = L.BlockNo $ fromIntegral $ unBlockNo blockNumber

--------------------------------------------------------------------------------
-- Valid for any era after Shelley
--------------------------------------------------------------------------------

-- | Construct a block given transactions and a header.
mkAnyAfterShelleyBlock
    :: ( L.EraBlockBody era
       , HeaderEra era ~ O.ShelleyProtocolHeader proto
       , TxT era2 ~ L.Tx L.TopTx era
       )
    => [Tx era2]
    -> HeaderEra era
    -> O.ShelleyBlock proto era
mkAnyAfterShelleyBlock txs header =
    O.ShelleyBlock (block txs' header) hash
  where
    txs' = unTx <$> txs

hash :: O.ShelleyHash
hash = O.ShelleyHash $ Crypto.UnsafeHash $ BS.pack $ replicate 32 42

block
    :: (L.EraBlockBody era)
    => [L.Tx L.TopTx era]
    -> HeaderEra era
    -> L.Block (HeaderEra era) era
block txs header' = Block header' (txseq txs)

txseq
    :: (L.EraBlockBody era)
    => [L.Tx L.TopTx era]
    -> L.BlockBody era
txseq txs =
    L.mkBasicBlockBody & L.txSeqBlockBodyL .~ Seq.fromList txs

type KES = Crypto.Sum6KES Crypto.Ed25519DSIGN Crypto.Blake2b_256

-- | Sign a value with a dummy KES key.
mkSignedKES
    :: SignableRepresentation a
    => a
    -> Crypto.SignedKES KES a
mkSignedKES hbody' = unsoundPureSignedKES () 42 hbody' unsoundPureKeyKES

-- | Dummy operational certificate.
oCertamente :: OCert StandardCrypto
oCertamente =
    OCert
        { ocertVkHot = unsoundPureDeriveVerKeyKES unsoundPureKeyKES
        , ocertN = 42
        , ocertKESPeriod = KESPeriod 42
        , ocertSigma = signedDSIGN () oCertSignable $ genKeyDSIGN seedKeyDSIGN
        }

oCertSignable :: OCertSignable StandardCrypto
oCertSignable =
    OCertSignable (unsoundPureDeriveVerKeyKES unsoundPureKeyKES) 42
        $ KESPeriod 42

unsoundPureKeyKES :: UnsoundPureSignKeyKES KES
unsoundPureKeyKES = unsoundPureGenKeyKES seedKeyKES

seedKeyKES :: Crypto.Seed
seedKeyKES =
    mkSeedFromBytes
        $ B8.pack
        $ flip replicate 'a'
        $ fromIntegral
        $ signKeySizeKES (Proxy @KES)

-- | Generate a dummy KES signing key.
mkKeyKES' :: UnsoundPureKESAlgorithm a => UnsoundPureSignKeyKES a
mkKeyKES' = unsoundPureGenKeyKES seedKeyKES

-- | Dummy body hash.
bodyHash :: Crypto.Hash Crypto.Blake2b_256 L.EraIndependentBlockBody
bodyHash = Crypto.UnsafeHash $ BS.pack $ replicate 32 42

seedKeyVRF :: Crypto.Seed
seedKeyVRF =
    mkSeedFromBytes
        $ B8.pack
        $ flip replicate 'a'
        $ fromIntegral
        $ sizeSignKeyVRF (Proxy :: Proxy PraosVRF)

-- | Generate a dummy VRF signing key.
mkKeyVRF' :: VRFAlgorithm a => SignKeyVRF a
mkKeyVRF' = genKeyVRF seedKeyVRF

-- | Dummy previous header hash.
hashHeader :: HashHeader
hashHeader = HashHeader $ Crypto.UnsafeHash $ BS.pack $ replicate 32 42

{-# NOINLINE seedKeyDSIGN #-}
seedKeyDSIGN :: Crypto.Seed
seedKeyDSIGN =
    mkSeedFromBytes
        $ B8.pack
        $ flip replicate 'a'
        $ fromIntegral
        $ Crypto.seedSizeDSIGN (Proxy :: Proxy Ed25519DSIGN)

-- | Generate a dummy DSIGN signing key.
mkKeyDSIGN' :: DSIGNAlgorithm a => SignKeyDSIGN a
mkKeyDSIGN' = genKeyDSIGN seedKeyDSIGN
