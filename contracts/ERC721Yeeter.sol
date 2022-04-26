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
import "./interfaces/IXERC721.sol";
import "./XERC721.sol";
import "./interfaces/IXChainContractRegistry.sol";
import "./lzApp/NonblockingLzApp.sol";

pragma solidity 0.8.11;

contract NFTYeeter is IERC721Receiver, NonblockingLzApp {


    IXChainContractRegistry public immutable registry;
    uint16 private immutable localChainId;
    mapping(address => mapping(uint256 => DepositDetails)) deposits; // deposits[collection][tokenId] = depositor
    mapping(uint16 => mapping(address => address)) localAddress; // localAddress[originChainId][collectionAddress]
    mapping(uint16 => mapping(address => IXERC721)) localContract; // localContract[originChainId][collectionAddress]

    struct DepositDetails {
        address depositor;
        bool bridged;
        uint256 dstChainId; // do we need to track this? could change w/o notifying home
                            // we could also "phone home" on bridging in order to notify
                            // but this would require two bridge calls, one to phone home,
                            // one to mint the new NFT on the new dstChainId
                            //
                            // we may want to know this for interface reasons, but don't
                            // need to store this on-chain
    }

        // if this big payload makes bridging expensive, we should separate
        // the process of bridging a collection (name, symbol) from bridging
        // of tokens (tokenId, tokenUri)
    struct BridgedTokenDetails {
        uint16 originChainId;
        address originAddress;
        uint256 tokenId;
        address owner;
        string name;
        string symbol;
        string tokenURI;
    }

    function getLocalAddress(uint16 originChainId, address originAddress) external view returns (address) {
        return localAddress[originChainId][originAddress];
    }

    constructor(uint16 _localChainId,
                IXChainContractRegistry _registry,
                address _endpoint)
        NonblockingLzApp(_endpoint)
    {
        localChainId = _localChainId;
        registry = _registry;
    }


    function withdraw(address collection, uint256 tokenId) external {
        DepositDetails memory details = deposits[collection][tokenId];
        require(details.bridged == false, "NFT Currently Bridged");
        require(details.depositor == msg.sender, "Unauth");
        IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // this function handles being notified that a tokenId was bridged to this chain
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        // check if this is a case of "bridging back" i.e. originChainId == localChainId
        // if so, set bridged to false, and note new owner

        (BridgedTokenDetails memory details) = abi.decode(_payload, (BridgedTokenDetails));

        if (details.originChainId == localChainId) {
            // we're bridging this NFT *back* home
            DepositDetails storage depositDetails = deposits[details.originAddress][details.tokenId];

            // record new owner to enable them to withdraw
            depositDetails.depositor = details.owner;

            // record that the NFT is *back* and does not exist on other chains
            depositDetails.bridged = false;

        } else if (localAddress[details.originChainId][details.originAddress] != address(0)) {
            // local XERC721 contract exists, we just need to mint
            IXERC721 nft = IXERC721(localAddress[details.originChainId][details.originAddress]);
            nft.mint(details.owner, details.tokenId, details.tokenURI);
        } else {
            // deploy new ERC721 contract
            XERC721 nft = new XERC721(details.name, details.symbol);
            localAddress[details.originChainId][details.originAddress] = address(nft);
            nft.mint(details.owner, details.tokenId, details.tokenURI);
        }

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
            (uint16 dstChainId) = abi.decode(data, (uint16));
            _bridgeToken(msg.sender, tokenId, from, dstChainId);
            deposits[msg.sender][tokenId] = DepositDetails({depositor: from, bridged: true, dstChainId: dstChainId});
        } else {
            deposits[msg.sender][tokenId] = DepositDetails({depositor: from, bridged: false, dstChainId: 0});
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function _bridgeToken(address collection, uint256 tokenId, address recipient, uint16 dstChainId) internal {
        address dstYeeter = bytesToAddress(trustedRemoteLookup[dstChainId]);
    }

}
