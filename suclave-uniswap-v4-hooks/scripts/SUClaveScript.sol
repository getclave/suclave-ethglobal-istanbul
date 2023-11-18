// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {FeeLibrary} from "@uniswap/v4-core/contracts/libraries/FeeLibrary.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";

import {SUClaveFactory} from "../src/hooks/SUClaveHook.sol";
import {CallType, UniswapV4Router} from "../src/router/UniswapV4Router.sol";
import {TestPoolManager} from "../test/utils/TestPoolManager.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
contract SUClaveScript is Script, TestPoolManager {
    PoolKey poolKey;
    uint256 privateKey;
    address signerAddr;
    address suaveAddr;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        privateKey2 = vm.envUint("PRIVATE_KEY2");
        signerAddr = vm.addr(privateKey);
        suaveAddr = vm.addr(privateKey2);
        console.log("signer %s", signerAddr);
        console.log("script %s", address(this));
        vm.startBroadcast(privateKey);

        TestPoolManager.initialize();

        // Deploy the hook
        SUClaveFactory factory = new SUClaveFactory();
        console.log("Deployed hook factory to address %s", address(factory));

        // If the PoolManager address is 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0,
        // the first salt from 0 to get the required address perfix is 1210.
        // Any changes to the DynamicFee contract will mean a different salt will be needed
        IHooks hook = IHooks(factory.mineDeploy(manager, suaveAddr, 1210));
        console.log("Deployed hook to address %s", address(hook));

        // Derive the key for the new pool
        poolKey = PoolKey(
            Currency.wrap(address(tokenA)), Currency.wrap(address(tokenB)), FeeLibrary.DYNAMIC_FEE_FLAG, 60, hook
        );
        // Create the pool in the Uniswap Pool Manager
        manager.initialize(poolKey, SQRT_RATIO_1_TO_1, "");

        console.log("currency0 %s", Currency.unwrap(poolKey.currency0));
        console.log("currency1 %s", Currency.unwrap(poolKey.currency1));

        // Provide liquidity to the pool
        caller.addLiquidity(poolKey, signerAddr, -60, 60, 10e18);
        caller.addLiquidity(poolKey, signerAddr, -120, 120, 20e18);
        caller.addLiquidity(poolKey, signerAddr, TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 30e18);

        vm.stopBroadcast();
    }

    function run() public {
        vm.startBroadcast(privateKey);

        caller.swap(poolKey, signerAddr, signerAddr, poolKey.currency0, 1e18);
        console.log("swapped token 0 for token 1 with normal address");

        // Deposit token 0 to the pool manager
        caller.deposit(address(tokenA), signerAddr, signerAddr, 6e18);

        // Withdraw token 0 to the pool manager
        manager.setApprovalForAll(address(caller), true);
        caller.withdraw(address(tokenA), signerAddr, 4e18);

        // Swap from token 0 to token 1 like a tx which comes from suave
        caller.swap(poolKey, suaveAddr, suaveAddr, poolKey.currency0, 1e18);
        console.log("swapped token 0 for token 1 with suave ");

        vm.stopBroadcast();
    }
}
