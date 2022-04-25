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
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/IXChainNFTRegistry.sol";
import "./lzApp/NonblockingLzApp.sol";

pragma solidity 0.8.11;

contract NFTYeeter is IERC721Receiver, NonblockingLzApp {

    IXChainNFTRegistry public immutable registry;

    struct DepositDetails {
        address depositor;
        bool bridged;
        uint256 dstChainId;
    }

    struct BridgedTokenDetails {
        uint256 originChainId;
        address originAddress;
        address localAddress;
        uint256 tokenId;
    }

    constructor(IXChainNFTRegistry _registry, address _endpoint) NonblockingLzApp(_endpoint) {
        registry = _registry;
    }

    mapping(address => mapping(uint256 => DepositDetails)) deposits; // deposits[collection][tokenId] = depositor

    function withdraw(address collection, uint256 tokenId) public {
        require(deposits[collection][tokenId].depositor == msg.sender, "Unauth");
        IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {

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
        if (data.length > 0) {
            (uint256 dstChainId) = abi.decode(data, (uint256));
            _bridgeToken(msg.sender, tokenId, from, dstChainId);
            deposits[msg.sender][tokenId] = DepositDetails({depositor: from, bridged: true, dstChainId: dstChainId});
        } else {
            deposits[msg.sender][tokenId] = DepositDetails({depositor: from, bridged: false, dstChainId: 0});
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function _bridgeToken(address collection, uint256 tokenId, address recipient, uint256 dstChainId) internal {
        //
    }

}
