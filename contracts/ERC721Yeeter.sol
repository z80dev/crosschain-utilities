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
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/IXERC721.sol";
import "./XERC721.sol";
import "./interfaces/IXChainContractRegistry.sol";
import "./lzApp/NonblockingLzApp.sol";

pragma solidity 0.8.11;

contract NFTYeeter is IERC721Receiver, NonblockingLzApp {

    uint16 private immutable localChainId;
    mapping(address => mapping(uint256 => DepositDetails)) deposits; // deposits[collection][tokenId] = depositor
    mapping(uint16 => mapping(address => address)) localAddress; // localAddress[originChainId][collectionAddress]

    // this is maintained on each "Home" chain where an NFT is originally locked
    struct DepositDetails {
        address depositor;
        bool bridged;
    }

    // this is used to mint new NFTs upon receipt
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
                address _endpoint)
        NonblockingLzApp(_endpoint)
    {
        localChainId = _localChainId;
    }


    function withdraw(address collection, uint256 tokenId) external {
        require(IERC721(collection).ownerOf(tokenId) == address(this), "NFT Not Deposited");
        DepositDetails memory details = deposits[collection][tokenId];
        require(details.bridged == false, "NFT Currently Bridged");
        require(details.depositor == msg.sender, "Unauth");
        IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // this function handles being notified that a tokenId was bridged to this chain
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64, bytes memory _payload) internal virtual override {
        // check if this is a case of "bridging back" i.e. originChainId == localChainId
        // if so, set bridged to false, and note new owner
        bool isTrustedRemote = keccak256(trustedRemoteLookup[_srcChainId]) == keccak256(_srcAddress);
        require(isTrustedRemote, "Unauth Remote");

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
            XERC721 nft = new XERC721(details.name, details.symbol, details.originAddress, details.originChainId);
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
            deposits[msg.sender][tokenId] = DepositDetails({depositor: from, bridged: true });
        } else {
            deposits[msg.sender][tokenId] = DepositDetails({depositor: from, bridged: false });
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function bridgeToken(address collection, uint256 tokenId, address recipient, uint16 dstChainId) external {
        require(IERC721(collection).ownerOf(tokenId) == address(this));
        require(deposits[collection][tokenId].depositor == msg.sender);
        require(deposits[collection][tokenId].bridged == false);
        _bridgeToken(collection, tokenId, recipient, dstChainId);
    }

    function _bridgeToken(address collection, uint256 tokenId, address recipient, uint16 dstChainId) internal {
        // should check length first
        // this will let us differentiate b/w evm addrs and cosmos addrs in the future
        // address dstYeeter = bytesToAddress(trustedRemoteLookup[dstChainId]);
        bytes memory dstYeeter = trustedRemoteLookup[dstChainId];
        require(dstYeeter.length > 0, "Chain not supported");
        IERC721Metadata nft = IERC721Metadata(collection);
        bytes memory payload = abi.encode(BridgedTokenDetails(localChainId,
                                                                            collection,
                                                                            tokenId,
                                                                            recipient,
                                                                            nft.name(),
                                                                            nft.symbol(),
                                                                            nft.tokenURI(tokenId)
                                                                            ));
        lzEndpoint.send{value: msg.value}(
                                        dstChainId,
                                        dstYeeter,
                                        payload,
                                        payable(msg.sender),
                                        address(0x0),
                                        abi.encode(
                                                   uint16(2),
                                                   uint(1000000),
                                                   uint(0),
                                                   recipient
)
                                        );
    }

}
