// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DCollection} from "../src/DCollection.sol";
import {TestUtils} from "./TestsSettingsAndUtils.t.sol";

contract BaseTestERC721Delegatable is Test, TestUtils {
    DCollection public collection;

    // Events for expectEvent
    event Delegated(
        address indexed from, address indexed to, uint256 indexed assetType, uint256 assetId, uint256 amount
    );
    event Undelegated(
        address indexed from, address indexed to, uint256 indexed assetType, uint256 assetId, uint256 amount
    );
    event UndelegatedAll(address indexed owner, uint256 indexed assetType, uint256 indexed assetId);

    function setUp() public virtual {
        collection = new DCollection(COLLECTION_NAME, COLLECTION_SYMBOL);
    }
}
