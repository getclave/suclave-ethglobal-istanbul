package main

import (
	"context"
	"crypto/ecdsa"
	"encoding/json"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/rpc"
	"github.com/ethereum/go-ethereum/suave/e2e"
	"github.com/ethereum/go-ethereum/suave/sdk"
)

var (
	accountCallerArtifact = e2e.AccountCaller
)

var (
	// This is the address we used when starting the MEVM
	exNodeEthAddr = common.HexToAddress("b5feafbdd752ad52afb7e1bd2e40432a485bbb7f")
	exNodeNetAddr = "http://localhost:8545"
	goerliNetAddr = "" //put goerli rpc
	// This account is funded in your local SUAVE network
	// address: 0xBE69d72ca5f88aCba033a063dF5DBe43a4148De0
	fundedAccount = newPrivKeyFromHex(
		"91ab9a7e53c220e6210460b65a7a3bb2ca181412a8a7b43ff336b3df1737ce12",
	)
)

func main() {
	client, err := ethclient.Dial(goerliNetAddr)
	rpcClient, _ := rpc.Dial(exNodeNetAddr)
	if err != nil {
		log.Fatal(err)
	}

	mevmClt := sdk.NewClient(rpcClient, fundedAccount.priv, exNodeEthAddr)

	privateKey, err := crypto.HexToECDSA("91ab9a7e53c220e6210460b65a7a3bb2ca181412a8a7b43ff336b3df1737ce12")
	if err != nil {
		log.Fatal(err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("error casting public key to ECDSA")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}

	value := big.NewInt(100000000000000000) // in wei (0.1 eth)
	gasLimit := uint64(220000)              // in units
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	toAddress := common.HexToAddress("0x11dc744F9b69b87a1eb19C3900e0fF85B6853990")
	var data []byte
	tx := types.NewTransaction(nonce, toAddress, value, gasLimit, gasPrice, data)

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatal(err)
	}

	targetBlock, _ := client.BlockNumber(context.Background())

	signedTxData, err := signedTx.MarshalJSON()
	if err != nil {
		log.Fatal(err)
	}

	revertingHashes := []common.Hash{crypto.Keccak256Hash(signedTxData)}

	bundle := &types.SBundle{
		BlockNumber:     big.NewInt(int64(targetBlock + 1)),
		Txs:             types.Transactions{signedTx},
		RevertingHashes: revertingHashes,
	}
	bundleBytes, err := json.Marshal(bundle)
	if err != nil {
		fmt.Println(err)
		return
	}

	var accountCallerContract *sdk.Contract = sdk.GetContract(common.HexToAddress("0xd594760B2A36467ec7F0267382564772D7b0b73c"), accountCallerArtifact.Abi, mevmClt)

	args := []interface{}{bundleBytes}

	transactionResult, err := accountCallerContract.SendTransaction(
		"callAccount",
		args,
		nil,
	)
	if err != nil {
		fmt.Println(err)
		return
	}
	newReceipt, err := transactionResult.Wait()
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Printf("%v\n", newReceipt)
}

type privKey struct {
	priv *ecdsa.PrivateKey
}

func newPrivKeyFromHex(hex string) *privKey {
	key, err := crypto.HexToECDSA(hex)
	if err != nil {
		panic(fmt.Sprintf("failed to parse private key: %v", err))
	}
	return &privKey{priv: key}
}
