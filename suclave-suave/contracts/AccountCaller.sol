// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./libraries/Suave.sol";

contract AccountCaller {
    function callback() external payable {
        // do nothing
    }

    function callAccount(
        bytes memory bundleData
    ) external view returns (bytes memory) {
        Suave.submitBundleJsonRPC(
            "https://relay-goerli.flashbots.net",
            "eth_sendBundle",
            bundleData
        );

        return abi.encodeWithSelector(this.callback.selector);
    }
}
