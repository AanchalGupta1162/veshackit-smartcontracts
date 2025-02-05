// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    // Constructor to set the token name, symbol, and initialize the owner
    constructor(
        address owner
    ) ERC721("Gift", "GFT") Ownable(owner) {}

    /**
     * @dev Mint a new NFT to the specified address
     * @param to Address of the recipient
     * @param tokenId Unique ID of the token
     * @param uri Metadata URI associated with the token
     */
    function mint(address to, uint256 tokenId, string calldata uri) external onlyOwner {
        require(to != address(0), "Invalid address");

        // Mint the token
        _mint(to, tokenId);

        // Set the token URI
        _setTokenURI(tokenId, uri);
    }
}