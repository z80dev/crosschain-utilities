// SPDX-License-Identifier: MIT
//
// TODO: only accept calls from trusted caller (i.e. NFTYeeter)

pragma solidity 0.8.11;

import "./interfaces/IXChainNFTRegistry.sol";

contract XChainNFTRegistry is IXChainNFTRegistry {

    mapping(uint256 => mapping(address => address)) localAddress; // localAddress[originChainId][collectionAddress]

    function getLocalChainAddress(uint256 originChainId, address originAddress) external view returns (address) {
        return localAddress[originChainId][originAddress];
    }
    function registerCollection(uint256 originChainId, address originAddress, string memory name, string memory symbol) external {

    }
}
