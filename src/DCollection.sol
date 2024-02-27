// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Delegatable} from "../src/ERC721Delegatable.sol";

/**
 * @title DCollection
 * @author @CarlosAlegreUr
 * @notice An ERC721 collection uses delegation extension implemented.
 * @dev The collection allows for minting and burning tokens. Anyone can mint
 * himnself a token but only the owner can burn its own tokens.
 */
contract DCollection is ERC721Delegatable {
    uint256 public s_nextId = 1;

    constructor(string memory _name, string memory _symbol) ERC721Delegatable(_name, _symbol) {}

    function mint(address _to) public {
        require(_to == msg.sender, "You can only mint to yourself.");
        _mint(_to, s_nextId++); /// @dev Not using _safeMint() for simpler invariant testing
    }

    function burn(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Only owner can burn token.");
        _burn(_tokenId);
    }
}
