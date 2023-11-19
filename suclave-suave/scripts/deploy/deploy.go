package main

import (
	"crypto/ecdsa"
	"fmt"

	_ "embed"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/rpc"
	"github.com/ethereum/go-ethereum/suave/e2e"
	"github.com/ethereum/go-ethereum/suave/sdk"
)

var (
	// This is the address we used when starting the MEVM
	exNodeEthAddr = common.HexToAddress("b5feafbdd752ad52afb7e1bd2e40432a485bbb7f")
	exNodeNetAddr = "http://localhost:8545"
	// This account is funded in your local SUAVE network
	// address: 0xBE69d72ca5f88aCba033a063dF5DBe43a4148De0
	fundedAccount = newPrivKeyFromHex(
		"91ab9a7e53c220e6210460b65a7a3bb2ca181412a8a7b43ff336b3df1737ce12",
	)
)

var (
	accountCallerArtifact = e2e.AccountCaller
)

func main() {
	rpcClient, _ := rpc.Dial(exNodeNetAddr)
	mevmClt := sdk.NewClient(rpcClient, fundedAccount.priv, exNodeEthAddr)

	var accountCallerContract *sdk.Contract
	_ = accountCallerContract

	txnResult, err := sdk.DeployContract(accountCallerArtifact.Code, mevmClt)
	if err != nil {
		fmt.Errorf("Failed to deploy contract: %v", err)
	}
	receipt, err := txnResult.Wait()
	if err != nil {
		fmt.Errorf("Failed to wait for transaction result: %v", err)
	}
	if receipt.Status == 0 {
		fmt.Errorf("Failed to deploy contract: %v", err)
	}

	fmt.Printf("- Account Caller contract deployed: %s\n", receipt.ContractAddress)

}

// Helpers, not unique to SUAVE

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
