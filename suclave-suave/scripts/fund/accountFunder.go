package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"os"

	_ "embed"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/rpc"
	"github.com/ethereum/go-ethereum/suave/sdk"
)

var (
	// This is the address we used when starting the MEVM
	exNodeEthAddr = common.HexToAddress("b5feafbdd752ad52afb7e1bd2e40432a485bbb7f")
	exNodeNetAddr = "http://localhost:8545"
	// This account is funded in your local network
	// address: 0xBE69d72ca5f88aCba033a063dF5DBe43a4148De0
	fundedAccount = newPrivKeyFromHex(
		"91ab9a7e53c220e6210460b65a7a3bb2ca181412a8a7b43ff336b3df1737ce12",
	)
)

func main() {
	rpcClient, _ := rpc.Dial(exNodeNetAddr)
	// Use the SDK to create a new client by specifying the Eth Address of the MEVM
	mevmClt := sdk.NewClient(rpcClient, fundedAccount.priv, exNodeEthAddr)

	testAddr1 := generatePrivKey()

	fundBalance := big.NewInt(100000000)
	if err := fundAccount(mevmClt, testAddr1.Address(), fundBalance); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		return
	}
	fmt.Printf("Funded test account: %s (%s)\n", testAddr1.Address().Hex(), fundBalance.String())
}

func fundAccount(clt *sdk.Client, to common.Address, value *big.Int) error {
	txn := &types.LegacyTx{
		Value: value,
		To:    &to,
	}
	result, err := clt.SendTransaction(txn)
	if err != nil {
		return err
	}
	_, err = result.Wait()
	if err != nil {
		return err
	}
	// check balance
	balance, err := clt.RPC().BalanceAt(context.Background(), to, nil)
	if err != nil {
		return err
	}
	if balance.Cmp(value) != 0 {
		return fmt.Errorf("failed to fund account")
	}
	return nil
}

// General types and methods we need for the above to work as we want it to,
// nothing SUAVE specific
type privKey struct {
	priv *ecdsa.PrivateKey
}

func (p *privKey) Address() common.Address {
	return crypto.PubkeyToAddress(p.priv.PublicKey)
}

func newPrivKeyFromHex(hex string) *privKey {
	key, err := crypto.HexToECDSA(hex)
	if err != nil {
		panic(fmt.Sprintf("failed to parse private key: %v", err))
	}
	return &privKey{priv: key}
}

func generatePrivKey() *privKey {
	key, err := crypto.GenerateKey()
	if err != nil {
		panic(fmt.Sprintf("failed to generate private key: %v", err))
	}
	return &privKey{priv: key}
}
