// SPDX-License-Identifier: MIT
//
// yeets your funds in and out of vaults from chain to chain
// supports withdrawing your funds and sending them cross-chain
// as well as receiving cross-chain funds and depositing them into a vault
//
//
// s/o to the Byte Masons for their code and support
// also some inspiration from sushiswap/bentobox-stargate

pragma solidity 0.8.11;

import "hardhat/console.sol";
import "./interfaces/IBasePool.sol";
import "./interfaces/IBaseWeightedPool.sol";
import "./interfaces/IBeetVault.sol";
import "./interfaces/IStargateReceiver.sol";
import "./interfaces/IAsset.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IStargateRouter.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

contract VaultYeeter is IStargateReceiver {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // certain functions should only be called by the trusted router
    IStargateRouter public immutable stargateRouter;
    address public immutable balVault;
    // address public constant BALANCER_VAULT = address(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);

    constructor(IStargateRouter _stargateRouter, address _balVault) {
        stargateRouter = _stargateRouter;
        balVault = _balVault;
    }

    // this will hold all the data we need to:
    // 1. Deposit our funds into Beethoven and obtain LPs
    // 2. Deposit those LPs into reaper and obtain vault shares
    // 3. Transfer those vault shares to the intended recipient
    struct YeetParams {
        IAsset[] underlyings;
        uint256 bridgedTokenIndex;
        bytes32 beetsPoolId;
        address lpToken; // needed for approval to deposit
        address vault;
        address recipient;
    }

    // this will hold data we need to fire off a cross-chain tx
    struct BridgeParams {
        uint16 dstChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        address token;
        uint256 amount;
        uint256 amountMin;
        uint256 dustAmount;
        address receiver; // contract address w/ sgReceive
    }

    // yeets funds cross-chain and into the desired vault
    // v0 simple version: take existing USDC balance, bridge it with the right calldata
    // later, we'll support swapping for USDC
    // then, we'll support withdrawing vault shares, converting those to USDC
    function yeet(YeetParams memory yeetParams, BridgeParams memory bridgeParams)
        external
        payable
    {
        // take user's funds
        IERC20Upgradeable(bridgeParams.token).safeTransferFrom(msg.sender, address(this), bridgeParams.amount);

        // construct payload
        bytes memory payload = abi.encode(yeetParams);

        IERC20Upgradeable(bridgeParams.token).safeIncreaseAllowance(address(stargateRouter), bridgeParams.amount);

        stargateRouter.swap{value: address(this).balance}(
            bridgeParams.dstChainId,
            bridgeParams.srcPoolId,
            bridgeParams.dstPoolId,
            payable(yeetParams.recipient),
            bridgeParams.amount,
            bridgeParams.amountMin,
            IStargateRouter.lzTxObj(
                500000, // works with 100k as well
                bridgeParams.dustAmount,
                abi.encodePacked(yeetParams.recipient)
            ),
            abi.encodePacked(bridgeParams.receiver),
            payload
        );


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
        // token indexes for balancer pools
        //
        // should only support a very limited subset of tokens/vaults initally
        // lets just do USDC-DEI "One God Between Two Stables Beethoven-X Crypt"
        bytes memory payload
    ) external override {
        require(
            msg.sender == address(stargateRouter),
            "Caller not Stargate Router"
        );

        (YeetParams memory yeet) = abi.decode(payload, (YeetParams));

        // TODO: What approvals do we need?

        // joins pool with bridged funds
        // no swapping needed because balancer supports depositing a single token
        // that makes up the pool, natively (awesome)
        //
        // there will be price impact
        //
        // TODO: how do we report potential price impact to users?
        // in meantime, only support very high liquidity pairs
        _joinPool(yeet.underlyings, amountLD, yeet.bridgedTokenIndex, yeet.beetsPoolId);

        // deposit into intended vault
        IERC20Upgradeable(yeet.lpToken).safeIncreaseAllowance(yeet.vault, IERC20Upgradeable(yeet.lpToken).balanceOf(address(this)));
        IVault(yeet.vault).depositAll();

        // we should now have vault shares
        // transfer shares to user
        IERC20Upgradeable(yeet.vault).safeTransfer(yeet.recipient, IERC20Upgradeable(yeet.vault).balanceOf(address(this)));
    }

    /**
     * @dev Joins {beetsPoolId} using {underlyings[tokenIndex]} balance;
     */
    function _joinPool(IAsset[] memory underlyings, uint256 amtIn, uint256 tokenIndex, bytes32 beetsPoolId) internal {
        IBaseWeightedPool.JoinKind joinKind = IBaseWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](underlyings.length);
        amountsIn[tokenIndex] = amtIn;
        uint256 minAmountOut = 1;
        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBeetVault.JoinPoolRequest memory request;
        request.assets = underlyings;
        request.maxAmountsIn = amountsIn;
        request.userData = userData;
        request.fromInternalBalance = false;

        IERC20Upgradeable(address(underlyings[tokenIndex])).safeIncreaseAllowance(balVault, amtIn);
        IBeetVault(balVault).joinPool(beetsPoolId, address(this), address(this), request);
    }


}
