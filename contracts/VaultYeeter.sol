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
    address public constant BEET_VAULT = address(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);

    constructor(IStargateRouter _stargateRouter) {
        stargateRouter = _stargateRouter;
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

        IERC20Upgradeable(address(underlyings[tokenIndex])).safeIncreaseAllowance(BEET_VAULT, amtIn);
        IBeetVault(BEET_VAULT).joinPool(beetsPoolId, address(this), address(this), request);
    }


}
