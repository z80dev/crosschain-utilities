// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IXChainContractRegistry {
    function getLocalAddress(uint256 originChainId, address originAddress) external view returns (address);
    function bridgeContract(uint256 dstChainId, address _contract) external;
}
