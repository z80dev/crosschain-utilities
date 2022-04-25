// SPDX-License-Identifier: MIT
//
// yeets your NFTs across chains
//
// locks on the originating chain
//
// can only be unlocked by bridging back
//
// upon landing on a new chain, a new ERC721 contract is deployed
//
// all the metadata from the original contract is copied to it
//
// this means all that data must be part of the payload
//
// maybe separate bridgeCollection/bridgeItem?
//
// when an item lands, a new tokenId for that NFT is minted
// with the metadata from the original chain
//
// interface has method for checking bridged collection address
//
// getLocalAddress(uint256 sourceChainID, address sourceAddress) (address)

// import "@rari-capital/solmate/src/tokens/ERC721.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

pragma solidity 0.8.11;

contract NFTYeeter is IERC721Receiver {

    mapping(address => mapping(uint256 => address)) deposits; // deposits[collection][tokenId] = depositor

    function withdraw(address collection, uint256 tokenId) public {
        require(deposits[collection][tokenId] == msg.sender, "Unauth");
        IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        deposits[msg.sender][tokenId] = from;
        return IERC721Receiver.onERC721Received.selector;
    }

}
