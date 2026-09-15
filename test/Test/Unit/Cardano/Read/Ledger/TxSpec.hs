{- |
Copyright: © 2024 Cardano Foundation
License: Apache-2.0

Example transactions for testing.
-}
module Test.Unit.Cardano.Read.Ledger.TxSpec
    ( byronTx
    , shelleyTx
    , allegraTx
    , maryTx
    , maryTxLongOutput
    , alonzoTx
    , babbageTx
    , conwayTx
    , dijkstraTx
    , spec
    ) where

import Prelude

import Cardano.Read.Ledger.Eras
    ( Allegra
    , Alonzo
    , Babbage
    , Byron
    , Conway
    , Dijkstra
    , IsEra
    , Mary
    , Shelley
    )
import Cardano.Read.Ledger.Eras.EraValue
    ( knownEras
    )
import Cardano.Read.Ledger.Tx.CBOR
    ( TxOutputBytesError (..)
    , TxWithOutputBytes (..)
    , deserializeTx
    , deserializeTxWithOutputBytes
    , serializeTx
    )
import Cardano.Read.Ledger.Tx.Output
    ( Output
    , deserializeOutput
    , serializeOutput
    )
import Cardano.Read.Ledger.Tx.Outputs
    ( getEraOutputsList
    )
import Cardano.Read.Ledger.Tx.Tx
    ( Tx
    )
import Data.ByteArray.Encoding
    ( Base (..)
    , convertFromBase
    )
import Data.ByteString
    ( ByteString
    )
import Data.ByteString qualified as BS
import Data.ByteString.Lazy
    ( fromStrict
    )
import Data.ByteString.Lazy qualified as BL
import Data.Word
    ( Word8
    )
import Test.Hspec
    ( Spec
    , describe
    , expectationFailure
    , it
    , shouldBe
    , shouldSatisfy
    )

{-----------------------------------------------------------------------------
    Test
------------------------------------------------------------------------------}

-- This transaction was assembled from the CBOR using
-- https://github.com/IntersectMBO/cardano-ledger
--   /blob/0a098670a7cf0d084c4087d4140f704f82784977
--      /eras/byron/ledger/impl/test/golden/cbor/utxo/Tx
--      /eras/byron/ledger/impl/test/golden/cbor/utxo/TxWitness
byronTx :: Tx Byron
byronTx =
    unsafeParseEraTxFromHex
        "82839f8200d81858258258204ba839c420b3d2bd439530f891cae9\
        \a5d4c4d812044630dac72e8e0962feeecc182fff9f8282d8185821\
        \83581caa5372095aaa680d19d4ca496983a145709c3be18b0d4c83\
        \cb7bdc5ea0001a32dc988e182fffa0818200D81858858258404B6D\
        \7977346C4453453553346653483665744E6F756958657A4379456A\
        \4B63337447346A61306B466A4F38717A616932365A4D5055454A66\
        \457931356F78356B5840688AAD857BC7FF30FC6862DA1BE281F420\
        \C65271B76AB19782FF40E2955AF88819C38E5C79138F28073ABAE1\
        \52C882258B4420A0C1C9FDD26C98812697FC3E00\
        \"

shelleyTx :: Tx Shelley
shelleyTx =
    unsafeParseEraTxFromHex
        "83a400828258200000000000000000000000000000000000000000\
        \000000000000000000000000008258200000000000000000000000\
        \000000000000000000000000000000000000000000010183825839\
        \010202020202020202020202020202020202020202020202020202\
        \020202020202020202020202020202020202020202020202020202\
        \0202021a005b8d8082583901030303030303030303030303030303\
        \030303030303030303030303030303030303030303030303030303\
        \03030303030303030303030303031a005b8d808258390104040404\
        \040404040404040404040404040404040404040404040404040404\
        \040404040404040404040404040404040404040404040404041a00\
        \7801e0021a0002102003191e46a10282845820130ae82201d7072e\
        \6fbfc0a1884fb54636554d14945b799125cf7ce38d477f51584058\
        \35ff78c6fc5e4466a179ca659fa85c99b8a3fba083f3f3f42ba360\
        \d479c64ef169914b52ade49b19a7208fd63a6e67a19c406b482660\
        \8fdc5307025506c307582001010101010101010101010101010101\
        \0101010101010101010101010101010144a1024100845820010000\
        \000000000000000000000000000000000000000000000000000000\
        \00005840e8e769ecd0f3c538f0a5a574a1c881775f086d6f4c845b\
        \81be9b78955728bffa7efa54297c6a5d73337bd6280205b1759c13\
        \f79d4c93f29871fc51b78aeba80e58200000000000000000000000\
        \00000000000000000000000000000000000000000044a1024100f6"

allegraTx :: Tx Allegra
allegraTx =
    unsafeParseEraTxFromHex
        "83a400828258200000000000000000000000000000000000000000\
        \000000000000000000000000008258200000000000000000000000\
        \000000000000000000000000000000000000000000010183825839\
        \010202020202020202020202020202020202020202020202020202\
        \020202020202020202020202020202020202020202020202020202\
        \0202021a005b8d8082583901030303030303030303030303030303\
        \030303030303030303030303030303030303030303030303030303\
        \03030303030303030303030303031a005b8d808258390104040404\
        \040404040404040404040404040404040404040404040404040404\
        \040404040404040404040404040404040404040404040404041a00\
        \7801e0021a0002102003191e46a10282845820130ae82201d7072e\
        \6fbfc0a1884fb54636554d14945b799125cf7ce38d477f51584058\
        \35ff78c6fc5e4466a179ca659fa85c99b8a3fba083f3f3f42ba360\
        \d479c64ef169914b52ade49b19a7208fd63a6e67a19c406b482660\
        \8fdc5307025506c307582001010101010101010101010101010101\
        \0101010101010101010101010101010144a1024100845820010000\
        \000000000000000000000000000000000000000000000000000000\
        \00005840e8e769ecd0f3c538f0a5a574a1c881775f086d6f4c845b\
        \81be9b78955728bffa7efa54297c6a5d73337bd6280205b1759c13\
        \f79d4c93f29871fc51b78aeba80e58200000000000000000000000\
        \00000000000000000000000000000000000000000044a1024100f6"

maryTx :: Tx Mary
maryTx =
    unsafeParseEraTxFromHex
        "83a400828258200000000000000000000000000000000000000000\
        \000000000000000000000000008258200000000000000000000000\
        \000000000000000000000000000000000000000000010183825839\
        \010202020202020202020202020202020202020202020202020202\
        \020202020202020202020202020202020202020202020202020202\
        \0202021a005b8d8082583901030303030303030303030303030303\
        \030303030303030303030303030303030303030303030303030303\
        \03030303030303030303030303031a005b8d808258390104040404\
        \040404040404040404040404040404040404040404040404040404\
        \040404040404040404040404040404040404040404040404041a00\
        \7801e0021a0002102003191e46a10282845820130ae82201d7072e\
        \6fbfc0a1884fb54636554d14945b799125cf7ce38d477f51584058\
        \35ff78c6fc5e4466a179ca659fa85c99b8a3fba083f3f3f42ba360\
        \d479c64ef169914b52ade49b19a7208fd63a6e67a19c406b482660\
        \8fdc5307025506c307582001010101010101010101010101010101\
        \0101010101010101010101010101010144a1024100845820010000\
        \000000000000000000000000000000000000000000000000000000\
        \00005840e8e769ecd0f3c538f0a5a574a1c881775f086d6f4c845b\
        \81be9b78955728bffa7efa54297c6a5d73337bd6280205b1759c13\
        \f79d4c93f29871fc51b78aeba80e58200000000000000000000000\
        \00000000000000000000000000000000000000000044a1024100f6"

{- Interesting example of a transaction on Mainnet in the Mary era.

The address of the first output of this transaction
has more bytes than are parsed by the ledger
— the ledger silently discards extra bytes at the end of the address.
In other words, serializing the address after parsing
will give a different result than the bytes recorded here.

See also
https://github.com/IntersectMBO/cardano-ledger/commit/ca351b80a7977a45cf4bcb9028b0a87436d2f448
-}
maryTxLongOutput :: Tx Mary
maryTxLongOutput =
    unsafeParseEraTxFromHex
        "83a40083825820bf4f8f6287993e17f785c949ef287416ba784198\
        \bb0ee12b2c7720cbffecd26f0082582052cf971bee4ba1b4e3b32b\
        \762e0bc3f7af83700bc8897eddbd77bd425dd28e8300825820bf4f\
        \8f6287993e17f785c949ef287416ba784198bb0ee12b2c7720cbff\
        \ecd26f01018282584e015bad085057ac10ecc7060f7ac41edd6f63\
        \068d8963ef7d86ca58669e5ecf2d283418a60be5a848a2380eb721\
        \000da1e0bbf39733134beca4cb57afb0b35fc89c63061c9914e055\
        \001a518c75161a035377d082583901f4e9e89cc628b9204fd6e2f4\
        \ae3e875aa0591fc2eb45b721520d2d22f4e9e89cc628b9204fd6e2\
        \f4ae3e875aa0591fc2eb45b721520d2d221a2c651d70021a000315\
        \70031a05f5e100a10083825820ec791e29bdb3157589872d3678db\
        \93f661d72ac18204759fa5e8d630eee1e66a58408944366b1015ee\
        \38809356ec48a59277701d40772a232c7cbb1e9510f2c632537d16\
        \318ba30a06953401dc2bfd693a34dc73d482050e6ccdea5811d0e1\
        \e32507825820ec791e29bdb3157589872d3678db93f661d72ac182\
        \04759fa5e8d630eee1e66a58408944366b1015ee38809356ec48a5\
        \9277701d40772a232c7cbb1e9510f2c632537d16318ba30a069534\
        \01dc2bfd693a34dc73d482050e6ccdea5811d0e1e32507825820ec\
        \791e29bdb3157589872d3678db93f661d72ac18204759fa5e8d630\
        \eee1e66a58408944366b1015ee38809356ec48a59277701d40772a\
        \232c7cbb1e9510f2c632537d16318ba30a06953401dc2bfd693a34\
        \dc73d482050e6ccdea5811d0e1e32507f6"

alonzoTx :: Tx Alonzo
alonzoTx =
    unsafeParseEraTxFromHex
        "84a400828258200000000000000000000000000000000000000000\
        \000000000000000000000000008258200000000000000000000000\
        \000000000000000000000000000000000000000000010183825839\
        \010202020202020202020202020202020202020202020202020202\
        \020202020202020202020202020202020202020202020202020202\
        \0202021a005b8d8082583901030303030303030303030303030303\
        \030303030303030303030303030303030303030303030303030303\
        \03030303030303030303030303031a005b8d808258390104040404\
        \040404040404040404040404040404040404040404040404040404\
        \040404040404040404040404040404040404040404040404041a00\
        \7801e0021a0002102003191e46a10282845820130ae82201d7072e\
        \6fbfc0a1884fb54636554d14945b799125cf7ce38d477f51584058\
        \35ff78c6fc5e4466a179ca659fa85c99b8a3fba083f3f3f42ba360\
        \d479c64ef169914b52ade49b19a7208fd63a6e67a19c406b482660\
        \8fdc5307025506c307582001010101010101010101010101010101\
        \0101010101010101010101010101010144a1024100845820010000\
        \000000000000000000000000000000000000000000000000000000\
        \00005840e8e769ecd0f3c538f0a5a574a1c881775f086d6f4c845b\
        \81be9b78955728bffa7efa54297c6a5d73337bd6280205b1759c13\
        \f79d4c93f29871fc51b78aeba80e58200000000000000000000000\
        \00000000000000000000000000000000000000000044a1024100f5\
        \f6"

babbageTx :: Tx Babbage
babbageTx =
    unsafeParseEraTxFromHex
        "84a400818258200000000000000000000000000000000000000000\
        \000000000000000000000000000182a20058390101010101010101\
        \010101010101010101010101010101010101010101010101010101\
        \01010101010101010101010101010101010101010101011a001e84\
        \80a200583901020202020202020202020202020202020202020202\
        \020202020202020202020202020202020202020202020202020202\
        \0202020202020202011a0078175c021a0001faa403191e46a10281\
        \845820010000000000000000000000000000000000000000000000\
        \000000000000000058407154db81463825f150bb3b9b0824caf151\
        \3716f73498afe61d917a5621912a2b3df252bea14683a9ee56710d\
        \483a53a5aa35247e0d2b80e6300f7bdec763a20458200000000000\
        \000000000000000000000000000000000000000000000000000000\
        \44a1024100f5f6"

conwayTx :: Tx Conway
conwayTx =
    unsafeParseEraTxFromHex
        "84A5008182582000000000000000000000000000000000000000000000000000\
        \00000000000000000182A2005839010101010101010101010101010101010101\
        \0101010101010101010101010101010101010101010101010101010101010101\
        \01010101010101011A001E8480A2005839010202020202020202020202020202\
        \0202020202020202020202020202020202020202020202020202020202020202\
        \02020202020202020202011A0078175C021A0001FAA403191E46048183098200\
        \581C0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A8200\
        \581C0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0DA102\
        \8184582001000000000000000000000000000000000000000000000000000000\
        \0000000058407154DB81463825F150BB3B9B0824CAF1513716F73498AFE61D91\
        \7A5621912A2B3DF252BEA14683A9EE56710D483A53A5AA35247E0D2B80E6300F\
        \7BDEC763A2045820000000000000000000000000000000000000000000000000\
        \000000000000000044A1024100F5F6"

dijkstraTx :: Tx Dijkstra
dijkstraTx =
    unsafeParseEraTxFromHex
        "84A5008182582000000000000000000000000000000000000000000000000000\
        \00000000000000000182A2005839010101010101010101010101010101010101\
        \0101010101010101010101010101010101010101010101010101010101010101\
        \01010101010101011A001E8480A2005839010202020202020202020202020202\
        \0202020202020202020202020202020202020202020202020202020202020202\
        \02020202020202020202011A0078175C021A0001FAA403191E460E81581C0B0B\
        \0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0BA10281845820\
        \0100000000000000000000000000000000000000000000000000000000000000\
        \58407154DB81463825F150BB3B9B0824CAF1513716F73498AFE61D917A562191\
        \2A2B3DF252BEA14683A9EE56710D483A53A5AA35247E0D2B80E6300F7BDEC763\
        \A204582000000000000000000000000000000000000000000000000000000000\
        \0000000044A1024100F5F6"

-- | Parse a hex-encoded transaction into a particular era.
unsafeParseEraTxFromHex
    :: forall era. IsEra era => ByteString -> Tx era
unsafeParseEraTxFromHex bytes =
    either (error . show) id
        $ deserializeTx (unsafeReadBase16 bytes :: BL.ByteString)

unsafeReadBase16 :: ByteString -> BL.ByteString
unsafeReadBase16 = either reportError fromStrict . convertFromBase Base16
  where
    reportError = error "unsafeReadBase16: input not in Base16"

spec :: Spec
spec = do
    describe "unsafeParseEraTxFromHex" $ do
        it "parses byronTx"
            $ seq byronTx True
        it "parses shelleyTx"
            $ seq shelleyTx True
        it "parses allegraTx"
            $ seq allegraTx True
        it "parses maryTx"
            $ seq maryTx True
        it "parses maryTxLongOutput"
            $ seq maryTxLongOutput True
        it "parses alonzoTx"
            $ seq alonzoTx True
        it "parses babbageTx"
            $ seq babbageTx True
        it "parses conwayTx"
            $ seq conwayTx True
        it "parses dijkstraTx"
            $ seq dijkstraTx True
    describe "deserializeTxWithOutputBytes" $ do
        -- Adding an era adds a case arm to the function under test. Without
        -- this, the new arm would simply go untested: an era ladder can stop
        -- one rung short and nothing complains. This fails until the era is
        -- named in erasCoveredHere below.
        it "has a case here for every known era"
            $ length erasCoveredHere
            `shouldBe` length knownEras

        it "retains the output spans of a Shelley transaction"
            $ retainsOutputBytes shelleyTx
        it "retains the output spans of an Allegra transaction"
            $ retainsOutputBytes allegraTx
        it "retains the output spans of a Mary transaction"
            $ retainsOutputBytes maryTx
        it "retains the output spans of a Mary transaction with a long output"
            $ retainsOutputBytes maryTxLongOutput
        it "retains the output spans of an Alonzo transaction"
            $ retainsOutputBytes alonzoTx
        it "retains the output spans of a Babbage transaction"
            $ retainsOutputBytes babbageTx
        it "retains the output spans of a Conway transaction"
            $ retainsOutputBytes conwayTx
        it "retains the output spans of a Dijkstra transaction"
            $ retainsOutputBytes dijkstraTx

        it "rejects Byron, which has no outputs field to locate" $ do
            let result =
                    deserializeTxWithOutputBytes (serializeTx byronTx)
                        :: Either
                            TxOutputBytesError
                            (TxWithOutputBytes Byron)
            result `shouldBe` Left UnsupportedEra

        -- The Byron case above is a decision; this is the fact behind it.
        -- A Byron transaction is a positional array whose first element is
        -- itself an array, so there is no field number under which outputs
        -- could be found. This fails if that encoding ever changes, rather
        -- than agreeing with the code by construction.
        it "encodes a Byron body positionally, with no field numbers" $ do
            let byronBytes = BL.toStrict $ serializeTx byronTx
            BS.index byronBytes 0 `shouldSatisfy` isArrayHeader
            BS.index byronBytes 1 `shouldSatisfy` isArrayHeader
            BS.index byronBytes 1 `shouldSatisfy` (not . isMapHeader)

        -- Every other era keys its body by field number, which is what
        -- makes the outputs field locatable at all.
        it "encodes a keyed body from Shelley on" $ do
            let keyedBody tx = BS.index (BL.toStrict tx) 1
            keyedBody (serializeTx shelleyTx) `shouldSatisfy` isMapHeader
            keyedBody (serializeTx allegraTx) `shouldSatisfy` isMapHeader
            keyedBody (serializeTx maryTx) `shouldSatisfy` isMapHeader
            keyedBody (serializeTx alonzoTx) `shouldSatisfy` isMapHeader
            keyedBody (serializeTx babbageTx) `shouldSatisfy` isMapHeader
            keyedBody (serializeTx conwayTx) `shouldSatisfy` isMapHeader
            keyedBody (serializeTx dijkstraTx) `shouldSatisfy` isMapHeader

        it "rejects a transaction the era's ledger decoder does not accept"
            $ do
                let result =
                        deserializeTxWithOutputBytes (serializeTx babbageTx)
                            :: Either
                                TxOutputBytesError
                                (TxWithOutputBytes Shelley)
                result `shouldBe` Left InvalidTransaction

        it "returns bytes that a re-serialization does not reproduce" $ do
            TxWithOutputBytes{outputsWithBytes} <-
                expectRight
                    $ deserializeTxWithOutputBytes (serializeTx conwayTx)
                        `asTypeOfEra` conwayTx
            outputsWithBytes
                `shouldSatisfy` any
                    ( \(output, sourceBytes) ->
                        serializeOutput output /= sourceBytes
                    )

        it "preserves a noncanonical output span" $ do
            let canonicalTx = serializeTx conwayTx
            TxWithOutputBytes{outputsWithBytes} <-
                expectRight
                    $ deserializeTxWithOutputBytes canonicalTx
                        `asTypeOfEra` conwayTx
            (canonicalOutput, firstBytes) <- case outputsWithBytes of
                value : _ -> pure value
                [] ->
                    expectationFailure "expected a Conway output"
                        >> fail "missing output"
            let first = BL.toStrict firstBytes
            first `shouldSatisfy` BS.isPrefixOf (BS.pack [0xa2, 0x00])
            let noncanonical =
                    BS.take 1 first <> BS.pack [0x18, 0x00] <> BS.drop 2 first
            let (prefix, suffix) = BS.breakSubstring first $ BL.toStrict canonicalTx
            suffix `shouldSatisfy` (not . BS.null)
            let modified =
                    BL.fromStrict
                        $ prefix <> noncanonical <> BS.drop (BS.length first) suffix
            TxWithOutputBytes{outputsWithBytes = modifiedOutputs} <-
                expectRight
                    $ deserializeTxWithOutputBytes modified
                        `asTypeOfEra` conwayTx
            (output, source) <- case modifiedOutputs of
                value : _ -> pure value
                [] ->
                    expectationFailure "expected a modified Conway output"
                        >> fail "missing output"
            output `shouldBe` canonicalOutput
            BL.toStrict source `shouldBe` noncanonical
            serializeOutput output `shouldSatisfy` (/= source)

        it "preserves a noncanonical container header in Shelley"
            $ preservesNoncanonicalHeader shelleyTx
        it "preserves a noncanonical container header in Allegra"
            $ preservesNoncanonicalHeader allegraTx
        it "preserves a noncanonical container header in Mary"
            $ preservesNoncanonicalHeader maryTx
        it "preserves a noncanonical container header in Alonzo"
            $ preservesNoncanonicalHeader alonzoTx
        it "preserves a noncanonical container header in Babbage"
            $ preservesNoncanonicalHeader babbageTx
        it "preserves a noncanonical container header in Conway"
            $ preservesNoncanonicalHeader conwayTx
        it "preserves a noncanonical container header in Dijkstra"
            $ preservesNoncanonicalHeader dijkstraTx

        -- The structural pass has a "duplicate outputs field" guard, but it
        -- cannot be reached through this entry point: `deserializeTx` runs
        -- first and the ledger rejects the duplicate, so the error is
        -- `InvalidTransaction` and not `InvalidTransactionStructure`. This
        -- pins that ordering — it changes meaning if the passes are ever
        -- swapped.
        it "rejects a body carrying the outputs field twice, at the ledger" $ do
            let bytes = BL.toStrict $ serializeTx conwayTx
            TxWithOutputBytes{outputsWithBytes} <-
                expectRight
                    $ deserializeTxWithOutputBytes (serializeTx conwayTx)
                        `asTypeOfEra` conwayTx
            -- Key 1, a two-element array, then the two outputs verbatim:
            -- the whole outputs entry of the body map.
            let entry =
                    BS.pack [0x01, 0x82]
                        <> BL.toStrict (mconcat $ snd <$> outputsWithBytes)
                (before, rest) = BS.breakSubstring entry bytes
            rest `shouldSatisfy` (not . BS.null)
            -- Splice the entry in a second time and widen the body map
            -- header by one entry to keep the CBOR well formed.
            let bodyHeader = BS.index before 1
                duplicated =
                    BS.take 1 before
                        <> BS.singleton (bodyHeader + 1)
                        <> BS.drop 2 before
                        <> entry
                        <> rest
            bodyHeader `shouldSatisfy` isMapHeader
            (bodyHeader + 1) `shouldSatisfy` isMapHeader
            let result =
                    deserializeTxWithOutputBytes (BL.fromStrict duplicated)
                        `asTypeOfEra` conwayTx
            result `shouldBe` Left InvalidTransaction

{- | The eras this module exercises for 'deserializeTxWithOutputBytes': the
seven that support the capability, plus Byron, which is asserted to reject.

Hardfork: add the new era here, and give it a case above.
-}

-- | A CBOR definite- or indefinite-length array header byte.
isArrayHeader :: Word8 -> Bool
isArrayHeader b = b >= 0x80 && b <= 0x9f

-- | A CBOR definite- or indefinite-length map header byte.
isMapHeader :: Word8 -> Bool
isMapHeader b = b >= 0xa0 && b <= 0xbf

{- | Rewrite a CBOR container header that carries its length in the initial
byte into the equivalent one-byte-length form: @0x83@ becomes @0x98 0x03@,
@0xa2@ becomes @0xb8 0x02@.

The result denotes the same value and is equally valid, but is not the
encoding a serializer would produce. It applies to both shapes an output
takes across the eras — an array up to Alonzo, a map from Babbage on —
which the era-specific edits below it cannot.
-}
widenContainerHeader :: BS.ByteString -> Maybe BS.ByteString
widenContainerHeader out = case BS.uncons out of
    Just (header, rest)
        | header >= 0x80 && header <= 0x97 ->
            Just $ BS.pack [0x98, header - 0x80] <> rest
        | header >= 0xa0 && header <= 0xb7 ->
            Just $ BS.pack [0xb8, header - 0xa0] <> rest
    _ -> Nothing

{- | An output whose container header is re-encoded noncanonically comes back
byte-for-byte as it was written, and still denotes the canonical value.

This is the property the capability exists for, so it is asserted at every
era that supports it rather than at one.
-}
preservesNoncanonicalHeader
    :: forall era
     . (IsEra era, Eq (Output era), Show (Output era))
    => Tx era
    -> IO ()
preservesNoncanonicalHeader tx = do
    let canonicalTx = BL.toStrict $ serializeTx tx
    TxWithOutputBytes{outputsWithBytes} <-
        expectRight $ deserializeTxWithOutputBytes (serializeTx tx)
    (canonicalOutput, firstBytes) <- case outputsWithBytes of
        value : _ -> pure value
        [] -> expectationFailure "expected an output" >> fail "no output"
    let canonicalFirst = BL.toStrict firstBytes
    noncanonical <- case widenContainerHeader canonicalFirst of
        Just value -> pure value
        Nothing ->
            expectationFailure "output is not a length-in-header container"
                >> fail "cannot perturb"
    noncanonical `shouldSatisfy` (/= canonicalFirst)
    let (before, rest) = BS.breakSubstring canonicalFirst canonicalTx
    rest `shouldSatisfy` (not . BS.null)
    let modified =
            BL.fromStrict
                $ before
                    <> noncanonical
                    <> BS.drop (BS.length canonicalFirst) rest
    TxWithOutputBytes{outputsWithBytes = modifiedOutputs} <-
        expectRight $ deserializeTxWithOutputBytes modified `asTypeOfEra` tx
    (output, source) <- case modifiedOutputs of
        value : _ -> pure value
        [] ->
            expectationFailure "expected a perturbed output"
                >> fail "no output"
    output `shouldBe` canonicalOutput
    BL.toStrict source `shouldBe` noncanonical
    serializeOutput output `shouldSatisfy` (/= source)

erasCoveredHere :: [String]
erasCoveredHere =
    [ "Byron"
    , "Shelley"
    , "Allegra"
    , "Mary"
    , "Alonzo"
    , "Babbage"
    , "Conway"
    , "Dijkstra"
    ]

{- | Every ordinary output of the transaction is returned, in source order,
paired with bytes that ledger-decode back to that same output.
-}
retainsOutputBytes
    :: forall era
     . ( IsEra era
       , Eq (Tx era)
       , Show (Tx era)
       , Eq (Output era)
       , Show (Output era)
       )
    => Tx era
    -> IO ()
retainsOutputBytes tx = do
    let bytes = serializeTx tx
    TxWithOutputBytes{transaction, outputsWithBytes} <-
        expectRight $ deserializeTxWithOutputBytes bytes
    transaction `shouldBe` tx
    (fst <$> outputsWithBytes) `shouldBe` getEraOutputsList tx
    outputsWithBytes
        `shouldSatisfy` all
            ( \(output, sourceBytes) ->
                either (const False) (== output)
                    $ deserializeOutput sourceBytes
            )
    -- The spans are the transaction's own bytes, not a re-encoding: the
    -- outputs are adjacent inside the outputs array, so their
    -- concatenation occurs verbatim in the source.
    BL.toStrict bytes
        `shouldSatisfy` BS.isInfixOf
            (BL.toStrict $ mconcat $ snd <$> outputsWithBytes)

{- | Fix the era of a 'deserializeTxWithOutputBytes' result to the era of an
example transaction, so that a call site does not need a type annotation.
-}
asTypeOfEra
    :: Either TxOutputBytesError (TxWithOutputBytes era)
    -> Tx era
    -> Either TxOutputBytesError (TxWithOutputBytes era)
asTypeOfEra result _ = result

expectRight :: Show error => Either error value -> IO value
expectRight =
    either
        (\err -> expectationFailure (show err) >> fail "unexpected Left")
        pure
