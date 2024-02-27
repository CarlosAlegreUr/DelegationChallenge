// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DCollection} from "../src/DCollection.sol";
import {BaseScript} from "./BaseScript.sol";
import "forge-std/console.sol";

contract CollectionScript is BaseScript {
    DCollection public collection;

    function setUp() public {
        collection = DCollection(_parseContractAddress(block.chainid));
    }

    function mint() public {
        vm.startBroadcast();
        uint256 nftMinted = DCollection(collection).s_nextId();
        DCollection(collection).mint(msg.sender);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("NFT ID MINTED: ", nftMinted);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        vm.stopBroadcast();
    }

    function burn(uint256 nftIdToBurn) public {
        vm.startBroadcast();
        DCollection(collection).burn(nftIdToBurn);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("NFT ID BURNED: ", nftIdToBurn);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        vm.stopBroadcast();
    }

    function transfer(address to, uint256 nftIdToTransfer) public {
        vm.startBroadcast();
        DCollection(collection).safeTransferFrom(msg.sender, to, nftIdToTransfer);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("NFT ID TRANSFERRED: ", nftIdToTransfer);
        console.log("TO: ", to);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        vm.stopBroadcast();
    }

    function delegateTo(address delegatee, uint256 nftIdToDelegate) public {
        vm.startBroadcast();
        DCollection(collection).delegateTo(delegatee, nftIdToDelegate, 1);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("DELEGATED");
        console.log("NFT ID: ", nftIdToDelegate);
        console.log("TO: ", delegatee);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        vm.stopBroadcast();
    }

    function undelegateFrom(address delegatee, uint256 nftIdToDelegate) public {
        vm.startBroadcast();
        DCollection(collection).undelegateFrom(delegatee, nftIdToDelegate, 1);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("UNDELEGATED");
        console.log("NFT ID: ", nftIdToDelegate);
        console.log("FROM: ", delegatee);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        vm.stopBroadcast();
    }

    function undelegateFromAll() public {
        vm.startBroadcast();
        DCollection(collection).undelegateFromAll(69);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("ALL YOUR DELEGATED NFTS ARE NOW UNDELEGATED");
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        vm.stopBroadcast();
    }

    function isDelegatee(address delegator, address delegatee, uint256 nftId) public {
        vm.startBroadcast();
        bool result = DCollection(collection).isDelegatee(delegator, delegatee, nftId, 1);
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log(" ");
        console.log("HAS DELEGATOR: ", delegator);
        console.log("DELEGATED NFT ID: ", nftId);
        console.log("TO ADDRESS: ", delegatee, "?");
        console.log("ANSWER: ", result);
        console.log(" ");
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        console.log("++++++++++++++++++++++++++++++++++++++++++++");
        vm.stopBroadcast();
    }
}
