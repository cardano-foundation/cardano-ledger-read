{-# LANGUAGE UndecidableInstances #-}

{- |
Copyright: © 2020-2022 IOHK, 2024 Cardano Foundation
License: Apache-2.0

Binary serialization of transactions.
-}
module Cardano.Read.Ledger.Tx.CBOR
    ( -- * Serialization
      serializeTx

      -- * Deserialization
    , deserializeTx
    , TxWithOutputBytes (..)
    , TxOutputBytesError (..)
    , deserializeConwayTxWithOutputBytes
    , deserializeDijkstraTxWithOutputBytes
    )
where

import Prelude

import Cardano.Ledger.Api
    ( eraProtVerLow
    )
import Cardano.Ledger.Binary
    ( DecCBOR (decCBOR)
    , DecoderError
    , EncCBOR
    , byronProtVer
    , decodeFull
    , decodeFullAnnotator
    )
import Cardano.Ledger.Binary.Encoding qualified as Ledger
import Cardano.Read.Ledger.Eras
    ( Conway
    , Dijkstra
    , Era (..)
    , IsEra (..)
    )
import Cardano.Read.Ledger.Tx.Output
    ( Output (..)
    , deserializeOutput
    )
import Cardano.Read.Ledger.Tx.Outputs
    ( Outputs (..)
    , getEraOutputs
    )
import Cardano.Read.Ledger.Tx.Tx
    ( Tx (..)
    , TxT
    )
import Codec.CBOR.Decoding
    ( ByteOffset
    , Decoder
    , decodeBreakOr
    , decodeInteger
    , decodeListLenOrIndef
    , decodeMapLenOrIndef
    , peekByteOffset
    )
import Codec.CBOR.Read
    ( deserialiseFromBytes
    )
import Codec.CBOR.Term
    ( decodeTerm
    )
import Control.Monad
    ( replicateM
    , replicateM_
    , unless
    , when
    )
import Data.ByteString.Lazy qualified as BL
import Data.Foldable
    ( toList
    )
import Data.Maybe
    ( isJust
    )

{-# INLINEABLE serializeTx #-}

-- | CBOR serialization of a tx in any era.
serializeTx :: forall era. IsEra era => Tx era -> BL.ByteString
serializeTx = case era of
    Byron -> f (versionForEra era)
    Shelley -> f (versionForEra era)
    Allegra -> f (versionForEra era)
    Mary -> f (versionForEra era)
    Alonzo -> f (versionForEra era)
    Babbage -> f (versionForEra era)
    Conway -> f (versionForEra era)
    Dijkstra -> f (versionForEra era)
  where
    era = theEra :: Era era

    f :: EncCBOR (TxT era) => Ledger.Version -> Tx era -> BL.ByteString
    f protVer = Ledger.serialize protVer . unTx

{-# INLINEABLE deserializeTx #-}

-- | CBOR deserialization of a tx in any era.
deserializeTx
    :: forall era
     . IsEra era
    => BL.ByteString -> Either DecoderError (Tx era)
deserializeTx = case era of
    Byron -> fmap Tx . decodeFull (versionForEra era)
    Shelley -> decodeTx (versionForEra era) "ShelleyTx"
    Allegra -> decodeTx (versionForEra era) "AllegraTx"
    Mary -> decodeTx (versionForEra era) "MaryTx"
    Alonzo -> decodeTx (versionForEra era) "AlonzoTx"
    Babbage -> decodeTx (versionForEra era) "BabbageTx"
    Conway -> decodeTx (versionForEra era) "ConwayTx"
    Dijkstra -> decodeTx (versionForEra era) "DijkstraTx"
  where
    era = theEra :: Era era
    decodeTx protVer label =
        fmap Tx . decodeFullAnnotator protVer label decCBOR

data TxWithOutputBytes era = TxWithOutputBytes
    { transaction :: !(Tx era)
    , outputsWithBytes :: ![(Output era, BL.ByteString)]
    }

deriving instance
    (Eq (Tx era), Eq (Output era)) => Eq (TxWithOutputBytes era)
deriving instance
    (Show (Tx era), Show (Output era)) => Show (TxWithOutputBytes era)

data TxOutputBytesError
    = InvalidConwayTransaction
    | InvalidDijkstraTransaction
    | InvalidTransactionStructure
    | OutputSpanMismatch
    deriving (Eq, Show)

{- | Decode a complete Conway transaction and retain each ordinary output's
exact source bytes. The structural pass is accepted only when every captured
span ledger-decodes to the corresponding output from the validated tx.
-}
deserializeConwayTxWithOutputBytes
    :: BL.ByteString -> Either TxOutputBytesError (TxWithOutputBytes Conway)
deserializeConwayTxWithOutputBytes =
    deserializeTxWithOutputBytes InvalidConwayTransaction $ \tx ->
        let Outputs ledgerOutputs = getEraOutputs tx
        in  Output <$> toList ledgerOutputs

{- | Decode a complete Dijkstra transaction and retain each ordinary output's
exact source bytes. The structural pass is accepted only when every captured
span ledger-decodes to the corresponding output from the validated tx.
-}
deserializeDijkstraTxWithOutputBytes
    :: BL.ByteString
    -> Either TxOutputBytesError (TxWithOutputBytes Dijkstra)
deserializeDijkstraTxWithOutputBytes =
    deserializeTxWithOutputBytes InvalidDijkstraTransaction $ \tx ->
        let Outputs ledgerOutputs = getEraOutputs tx
        in  Output <$> toList ledgerOutputs

deserializeTxWithOutputBytes
    :: forall era
     . (IsEra era, Eq (Output era))
    => TxOutputBytesError
    -> (Tx era -> [Output era])
    -> BL.ByteString
    -> Either TxOutputBytesError (TxWithOutputBytes era)
deserializeTxWithOutputBytes invalidTransaction getOutputs bytes = do
    transaction <-
        either (const $ Left invalidTransaction) Right
            $ deserializeTx bytes
    spans <- case deserialiseFromBytes decodeTransactionOutputSpans bytes of
        Left _ -> Left InvalidTransactionStructure
        Right (remaining, values)
            | BL.null remaining -> Right values
            | otherwise -> Left InvalidTransactionStructure
    let sourceBytes = slice bytes <$> spans
    decodedOutputs <-
        mapM
            ( either (const $ Left InvalidTransactionStructure) Right
                . deserializeOutput
            )
            sourceBytes
    unless (decodedOutputs == getOutputs transaction)
        $ Left OutputSpanMismatch
    pure
        TxWithOutputBytes
            { transaction
            , outputsWithBytes = zip decodedOutputs sourceBytes
            }
  where
    slice source (start, end) =
        BL.take (fromIntegral $ end - start)
            $ BL.drop (fromIntegral start) source

decodeTransactionOutputSpans :: Decoder s [(ByteOffset, ByteOffset)]
decodeTransactionOutputSpans = do
    outerLength <- decodeListLenOrIndef
    spans <- decodeBody
    finishCollection outerLength 1
    pure spans
  where
    decodeBody = do
        bodyLength <- decodeMapLenOrIndef
        values <- decodeMapEntries bodyLength Nothing
        maybe (fail "transaction body has no outputs") pure values

    decodeMapEntries (Just count) seen = go count seen
      where
        go 0 values = pure values
        go remaining values = decodeEntry values >>= go (remaining - 1)
    decodeMapEntries Nothing seen = do
        done <- decodeBreakOr
        if done
            then pure seen
            else decodeEntry seen >>= decodeMapEntries Nothing

    decodeEntry seen = do
        key <- decodeInteger
        if key == 1
            then do
                when (isJust seen) $ fail "duplicate outputs field"
                Just <$> decodeOutputArray
            else decodeTerm >> pure seen

    decodeOutputArray = do
        outputLength <- decodeListLenOrIndef
        decodeCollection outputLength $ do
            start <- peekByteOffset
            _ <- decodeTerm
            end <- peekByteOffset
            pure (start, end)

    decodeCollection (Just count) action = replicateM count action
    decodeCollection Nothing action = go
      where
        go = do
            done <- decodeBreakOr
            if done then pure [] else (:) <$> action <*> go

    finishCollection (Just count) consumed = do
        when (count < consumed) $ fail "transaction array is too short"
        replicateM_ (count - consumed) decodeTerm
    finishCollection Nothing _ = do
        done <- decodeBreakOr
        unless done $ decodeTerm >> finishCollection Nothing 0

{-# INLINE versionForEra #-}

-- | Protocol version that we use for encoding and decoding.
versionForEra :: forall era. Era era -> Ledger.Version
versionForEra era = case era of
    Byron -> byronProtVer
    Shelley -> eraProtVerLow @era
    Allegra -> eraProtVerLow @era
    Mary -> eraProtVerLow @era
    Alonzo -> eraProtVerLow @era
    Babbage -> eraProtVerLow @era
    Conway -> eraProtVerLow @era
    Dijkstra -> eraProtVerLow @era
