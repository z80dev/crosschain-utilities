// SPDX-License-Identifier: MIT
//
// yeets your funds in and out of vaults from chain to chain
//
// supports withdrawing your funds and sending them cross-chain
// as well as receiving cross-chain funds and depositing them into a vault

pragma solidity 0.8.11;

import "hardhat/console.sol";
import "./interfaces/IStargateReceiver.sol";
import "./interfaces/IStargateRouter.sol";

contract VaultYeeter is IStargateReceiver {

    // certain functions should only be called by the trusted router
    IStargateRouter public immutable stargateRouter;

    constructor(IStargateRouter _stargateRouter) {
        stargateRouter = _stargateRouter;
    }

    function sgReceive(

        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        // payload will contain all the data we need
        // what vault do we want to enter?
        // what LP token do we need?
        // is this a balancer(beethoven) pool?
        //
        // should only support a very limited subset of tokens/vaults initally
        // find best USDC liquidity
        bytes memory payload
    ) external override {
        require(
            msg.sender == address(stargateRouter),
            "Caller not Stargate Router"
        );

        // perform swap from USDC to necessary LP

        // deposit into intended vault

        // transfer shares to user
    }
}
