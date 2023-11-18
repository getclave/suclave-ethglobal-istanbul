// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IDynamicFeeManager} from "@uniswap/v4-core/contracts/interfaces/IDynamicFeeManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolKey, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {console} from "forge-std/console.sol";

contract SUClaveHook is BaseHook, IDynamicFeeManager {
    using PoolIdLibrary for PoolKey;
    address public suaveAddress;

    constructor(
        IPoolManager _poolManager,
        address _suaveAddress
    ) BaseHook(_poolManager) {
        suaveAddress = _suaveAddress;
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: true,
                afterModifyPosition: true,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function getFee(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata data
    ) external pure returns (uint24 fee) {
        address initiatorAddress = tx.origin;

        if (initiatorAddress == suaveAddress) {
            fee = 1500;
        } else {
            fee = 3000;
        }
    }

    function beforeModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        bytes calldata
    ) external override returns (bytes4 selector) {
        // insert hook logic here

        selector = BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) external override returns (bytes4 selector) {
        // insert hook logic here

        selector = BaseHook.afterModifyPosition.selector;
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external override returns (bytes4 selector) {
        // insert hook logic here

        selector = BaseHook.beforeSwap.selector;
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) external override returns (bytes4 selector) {
        // insert hook logic here

        selector = BaseHook.afterSwap.selector;
    }
}

contract SUClaveFactory is BaseFactory {
    constructor()
        BaseFactory(
            address(
                uint160(
                    Hooks.BEFORE_MODIFY_POSITION_FLAG |
                        Hooks.AFTER_MODIFY_POSITION_FLAG |
                        Hooks.BEFORE_SWAP_FLAG |
                        Hooks.AFTER_SWAP_FLAG
                )
            )
        )
    {}

    function deploy(
        IPoolManager poolManager,
        address suaveAddress,
        bytes32 salt
    ) public override returns (address) {
        return address(new SUClaveHook{salt: salt}(poolManager, suaveAddress));
    }

    function _hashBytecode(
        IPoolManager poolManager,
        address suaveAddress
    ) internal pure override returns (bytes32 bytecodeHash) {
        bytecodeHash = keccak256(
            abi.encodePacked(
                type(DynamicFeeHook).creationCode,
                abi.encode(poolManager, suaveAddress)
            )
        );
    }
}

abstract contract BaseFactory {
    /// @notice zero out all but the first byte of the address which is all 1's
    uint160 public constant UNISWAP_FLAG_MASK = 0xff << 152;

    // Uniswap hook contracts must have specific flags encoded in the first byte of their address
    address public immutable TargetPrefix;

    constructor(address _targetPrefix) {
        TargetPrefix = _targetPrefix;
    }

    function deploy(
        IPoolManager poolManager,
        address suaveAddress,
        bytes32 salt
    ) public virtual returns (address);

    function mineDeploy(
        IPoolManager poolManager,
        address suaveAddress
    ) external returns (address) {
        return mineDeploy(poolManager, suaveAddress, 0);
    }

    function mineDeploy(
        IPoolManager poolManager,
        address suaveAddress,
        uint256 startSalt
    ) public returns (address) {
        bytes32 salt = mineSalt(poolManager, suaveAddress, startSalt);
        return deploy(poolManager, suaveAddress,  salt);
    }

    function mineSalt(
        IPoolManager poolManager,
        address suaveAddress,
        uint256 startSalt
    ) public view returns (bytes32 salt) {
        uint256 endSalt = uint256(startSalt) + 1000;
        unchecked {
            for (uint256 i = startSalt; i < endSalt; ++i) {
                salt = bytes32(i);
                address hookAddress = _computeHookAddress(poolManager, suaveAddress, salt);

                if (_isPrefix(hookAddress)) {
                    console.log("Found salt %s for address %s", i, hookAddress);
                    return salt;
                }
            }
            revert("Failed to find a salt");
        }
    }

    function _computeHookAddress(
        IPoolManager poolManager,
        address suaveAddress,
        bytes32 salt
    ) internal view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                _hashBytecode(poolManager, suaveAddress)
            )
        );
        return address(uint160(uint256(hash)));
    }

    /// @dev The implementing contract must override this function to return the bytecode hash of its contract
    /// For example, the CounterHook contract would return:
    /// bytecodeHash = keccak256(abi.encodePacked(type(CounterHook).creationCode, abi.encode(poolManager)));
    function _hashBytecode(
        IPoolManager poolManager,
        address suaveAddress
    ) internal pure virtual returns (bytes32 bytecodeHash);

    function _isPrefix(address _address) internal view returns (bool) {
        // zero out all but the first byte of the address
        address actualPrefix = address(uint160(_address) & UNISWAP_FLAG_MASK);
        return actualPrefix == TargetPrefix;
    }
}
