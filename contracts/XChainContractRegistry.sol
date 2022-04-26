// SPDX-License-Identifier: MIT
//
// TODO: only accept calls from trusted caller (i.e. NFTYeeter)

pragma solidity 0.8.11;

import "./interfaces/IXChainContractRegistry.sol";
import "./lzApp/NonblockingLzApp.sol";

contract XChainContractRegistry is IXChainContractRegistry, NonblockingLzApp {

    mapping(uint256 => mapping(address => address)) localAddress; // localAddress[originChainId][collectionAddress]

    function getLocalAddress(uint256 originChainId, address originAddress) external view returns (address) {
        return localAddress[originChainId][originAddress];
    }

    constructor(address _endpoint) NonblockingLzApp(_endpoint) {}

    // this function handles being notified that a collection is being bridged
    // should note originChainId, originAddress, deploy new contract, and store mapping between these
    // so anyone can look up the local contract given an originChainId and originAddress
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {

    }

    // gets called to bridge contract, i.e. trigger deployment of erc721 on other chain
    // i.e. calling this on chain A results in _nonblockingLzReceive being called on chain B
    function bridgeContract(uint256 dstChainId, address _contract) external {
        // we need to send dstChain all the data it needs to deploy a valid erc721
        // initially we can only support contracts w/ a baseTokenURI...

    }
    
    function _registerCollection(uint256 originChainId, address originAddress, string memory name, string memory symbol) internal {
        // deploy new ERC721 here
    }
}
