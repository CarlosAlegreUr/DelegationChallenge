// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {DCollection} from "../src/DCollection.sol";

contract Deploy is BaseScript {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        DCollection dCollection = new DCollection("MyNFT", "MNFT");
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("DCollection deployed at: ", address(dCollection));
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        vm.stopBroadcast();
        _setNewCollectionAddress(block.chainid, address(dCollection));
    }
}
