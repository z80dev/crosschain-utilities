// SPDX-License-Identifier: AGPL-3.0-only
//
// an ERC721 geared towards cross-chain use
//
// mints w/ specified tokenURI for tokenId
//
// supports burning
//
// we should use proxy for this to save on deployments
// deploy one implementation and then keep deploying proxies
// so the code only gets deployed *once*

pragma solidity 0.8.11;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./interfaces/IXERC721.sol";

contract XERC721 is ERC721, IXERC721 {

    address public immutable minter;
    address public immutable originAddress;
    uint16 public immutable originChainId;
    mapping(uint256 => string) public _tokenURIs;

    constructor(string memory _name, string memory _symbol, address _originAddress, uint16 _originChainId) ERC721(_name, _symbol) {
        minter = msg.sender;
        originAddress = _originAddress;
        originChainId = _originChainId;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
       return _tokenURIs[id];
    }

    function mint(address _to, uint256 _id, string memory _tokenURI) public {
        require(minter == msg.sender, "UNAUTH");
        _safeMint(_to, _id);
        _tokenURIs[_id] = _tokenURI;
    }

    function burn(uint256 _id) public {
        require(minter == msg.sender, "UNAUTH");
        _burn(_id);
    }
}
