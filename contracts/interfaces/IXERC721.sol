
// SPDX-License-Identifier: AGPL-3.0-only
//
// an ERC721 geared towards cross-chain use
//
// mints w/ specified tokenURI for tokenId
//
// supports burning

pragma solidity 0.8.11;

interface IXERC721 {
    function mint(address _to, uint256 _id, string memory _tokenURI) external;
}
