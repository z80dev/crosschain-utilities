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


pragma solidity 0.8.11;

contract NFTYeeter {

}
