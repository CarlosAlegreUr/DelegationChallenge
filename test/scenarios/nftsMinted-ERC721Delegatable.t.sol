// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/Test.sol";
import {BaseTestERC721Delegatable} from "../BaseTestERC721Delegatable.t.sol";

/**
 * @notice Mints AMOUNT_OF_TOKENS_TO_MINT_EACH_USER nfts to AMOUNT_OF_USERS addresses.
 * @dev DCollection is an ERC721 collection with the delegate extension implemented.
 * The collection allows for anyone to mint and burn tokens, but only an owner can burn its own token.
 */
contract MintedTokensScenario is BaseTestERC721Delegatable {
    function setUp() public virtual override {
        BaseTestERC721Delegatable.setUp();
        for (uint256 i = 1; i <= AMOUNT_OF_USERS; i++) {
            for (uint256 j = 0; j < AMOUNT_OF_TOKENS_TO_MINT_EACH_USER; j++) {
                vm.prank(_getUser(i));
                collection.mint(_getUser(i));
            }
        }
    }
}
