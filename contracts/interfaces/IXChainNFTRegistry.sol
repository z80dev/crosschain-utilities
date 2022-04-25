// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IXChainNFTRegistry {
    function getLocalChainAddress(uint256 originChainId, address originAddress) external view returns (address);
    function registerCollection(uint256 originChainId, address originAddress, string memory name, string memory symbol) external;
}
