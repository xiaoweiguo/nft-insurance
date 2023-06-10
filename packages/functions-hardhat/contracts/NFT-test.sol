// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
using Strings for uint256;

contract Azuki2 is ERC721 {
    uint256 private _tokenId; // The tokenId of the token to be minted.
    mapping (uint256 => string) private _tokenURIs; // Optional mapping for token URIs
    string private _baseURIextended; // Base URI

    constructor(string memory name_, string memory symbol_)
        payable
        ERC721(name_, symbol_)
    {
        _tokenId = 0;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function mint(string memory tokenURI) public returns (uint256) {
        _tokenId += 1;
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, tokenURI);
        return _tokenId;
    }
}
