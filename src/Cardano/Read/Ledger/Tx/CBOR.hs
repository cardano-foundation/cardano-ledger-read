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

      -- * Deserialization retaining output source bytes
    , TxWithOutputBytes (..)
    , TxOutputBytesError (..)
    , deserializeTxWithOutputBytes
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
    ( Era (..)
    , IsEra (..)
    )
import Cardano.Read.Ledger.Tx.Output
    ( Output
    , deserializeOutput
    )
import Cardano.Read.Ledger.Tx.Outputs
    ( getEraOutputsList
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

{-----------------------------------------------------------------------------
    Deserialization retaining output source bytes
------------------------------------------------------------------------------}

{- | A ledger-validated transaction together with the exact source bytes of
each of its ordinary outputs.

Re-serializing a decoded output does not in general reproduce the bytes it
was decoded from: several valid CBOR encodings denote the same value. A
consumer that must present the original representation — rather than a
semantically equal one — needs the source bytes themselves.
-}
data TxWithOutputBytes era = TxWithOutputBytes
    { transaction :: !(Tx era)
    , outputsWithBytes :: ![(Output era, BL.ByteString)]
    }

deriving instance
    (Eq (Tx era), Eq (Output era)) => Eq (TxWithOutputBytes era)
deriving instance
    (Show (Tx era), Show (Output era)) => Show (TxWithOutputBytes era)

-- | Why 'deserializeTxWithOutputBytes' did not return output bytes.
data TxOutputBytesError
    = {- | The era does not represent a transaction as a body keyed by
      field number, so ordinary outputs have no span to capture.
      Byron is the only such era.
      -}
      UnsupportedEra
    | -- | The ledger decoder for the era rejected the transaction.
      InvalidTransaction
    | -- | Source-span extraction failed.
      InvalidTransactionStructure
    | -- | The captured outputs differ from the ledger-decoded outputs.
      OutputSpanMismatch
    deriving (Eq, Show)

{-# INLINEABLE deserializeTxWithOutputBytes #-}

{- | Decode a complete transaction in any era and retain each ordinary
output's exact source bytes.

The structural pass is accepted only when every captured span
ledger-decodes to the corresponding output of the validated transaction,
so the retained bytes cannot disagree with the ledger's own view of the
transaction. The ledger decoder remains the source of semantic validation;
the structural pass cannot make an invalid transaction valid.

Byron returns 'UnsupportedEra': a Byron transaction is a positional array
rather than a body keyed by field number, so there is no outputs field to
locate.

Hardfork: Update this function to the next era.
-}
deserializeTxWithOutputBytes
    :: forall era
     . IsEra era
    => BL.ByteString
    -> Either TxOutputBytesError (TxWithOutputBytes era)
deserializeTxWithOutputBytes = case theEra :: Era era of
    Byron -> const $ Left UnsupportedEra
    Shelley -> withOutputBytes
    Allegra -> withOutputBytes
    Mary -> withOutputBytes
    Alonzo -> withOutputBytes
    Babbage -> withOutputBytes
    Conway -> withOutputBytes
    Dijkstra -> withOutputBytes

{- | The era-independent body of 'deserializeTxWithOutputBytes'.

The 'Eq' constraint is discharged by the era case in
'deserializeTxWithOutputBytes' and so does not reach the public signature.
-}
withOutputBytes
    :: forall era
     . (IsEra era, Eq (Output era))
    => BL.ByteString
    -> Either TxOutputBytesError (TxWithOutputBytes era)
withOutputBytes bytes = do
    transaction <-
        either (const $ Left InvalidTransaction) Right
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
    unless (decodedOutputs == getEraOutputsList transaction)
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
