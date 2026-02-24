{- |
Copyright: © 2024 Cardano Foundation
License: Apache-2.0

Block generation and accessor tests for all eras.
-}
module Test.Unit.Cardano.Read.Ledger.BlockSpec
    ( spec
    ) where

import Prelude

import Cardano.Read.Ledger.Block.BHeader
    ( getEraBHeader
    )
import Cardano.Read.Ledger.Block.Block
    ( fromConsensusBlock
    , toConsensusBlock
    )
import Cardano.Read.Ledger.Block.BlockNo
    ( BlockNo (..)
    , getEraBlockNo
    )
import Cardano.Read.Ledger.Block.Gen
    ( mkBlockEra
    )
import Cardano.Read.Ledger.Block.Gen.BlockParameters
    ( BlockParameters (..)
    )
import Cardano.Read.Ledger.Block.HeaderHash
    ( getEraHeaderHash
    )
import Cardano.Read.Ledger.Block.SlotNo
    ( SlotNo (..)
    , getEraSlotNo
    )
import Cardano.Read.Ledger.Block.Txs
    ( getEraTransactions
    )
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
    ( applyEraFun
    )
import Cardano.Read.Ledger.Tx.Tx
    ( Tx (..)
    )
import Test.Hspec
    ( Spec
    , describe
    , it
    , shouldBe
    )
import Test.Unit.Cardano.Read.Ledger.TxSpec
    ( allegraTx
    , alonzoTx
    , babbageTx
    , byronTx
    , conwayTx
    , dijkstraTx
    , maryTx
    , shelleyTx
    )

{-----------------------------------------------------------------------------
    Test
------------------------------------------------------------------------------}

spec :: Spec
spec = do
    describe "Byron" $ blockTests @Byron byronTx
    describe "Shelley" $ blockTests @Shelley shelleyTx
    describe "Allegra" $ blockTests @Allegra allegraTx
    describe "Mary" $ blockTests @Mary maryTx
    describe "Alonzo" $ blockTests @Alonzo alonzoTx
    describe "Babbage" $ blockTests @Babbage babbageTx
    describe "Conway" $ blockTests @Conway conwayTx
    describe "Dijkstra" $ blockTests @Dijkstra dijkstraTx

blockTests :: forall era. IsEra era => Tx era -> Spec
blockTests tx = do
    let params =
            BlockParameters
                { slotNumber = SlotNo 7
                , blockNumber = BlockNo 42
                , txs = [tx]
                }
        block = mkBlockEra params

    it "fromConsensusBlock . toConsensusBlock roundtrip" $ do
        let eraBlock = fromConsensusBlock (toConsensusBlock block)
        applyEraFun
            (getEraBlockNo . getEraBHeader)
            eraBlock
            `shouldBe` BlockNo 42
        applyEraFun
            (getEraSlotNo . getEraBHeader)
            eraBlock
            `shouldBe` SlotNo 7

    it "getEraBlockNo returns expected block number"
        $ getEraBlockNo (getEraBHeader block)
        `shouldBe` BlockNo 42

    it "getEraSlotNo returns expected slot number"
        $ getEraSlotNo (getEraBHeader block)
        `shouldBe` SlotNo 7

    it "getEraTransactions returns the embedded transaction"
        $ length (getEraTransactions block)
        `shouldBe` 1

    it "getEraHeaderHash is not bottom"
        $ seq (getEraHeaderHash block) True
        `shouldBe` True
