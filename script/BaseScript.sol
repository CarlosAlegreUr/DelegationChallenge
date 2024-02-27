// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";

/**
 * @notice BaseScript that can read and write to the comon json file for scripts.
 */
contract BaseScript is Script {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;

    string public constant jsonDataPath = "./script/scriptsData.json";

    function _parseContractAddress(uint256 _chainId) internal view returns (address c) {
        string memory jsonFile = vm.readFile(jsonDataPath);
        string memory jsonKey =
            _chainId == ETH_SEPOLIA_CHAIN_ID ? ".sepolia.collectionAddress" : ".anvil.collectionAddress";
        c = abi.decode(vm.parseJson(jsonFile, jsonKey), (address));
    }

    function _setNewCollectionAddress(uint256 _chainId, address _newAddress) internal {
        string memory jsonKey =
            _chainId == ETH_SEPOLIA_CHAIN_ID ? ".sepolia.collectionAddress" : ".anvil.collectionAddress";

        string memory obj1 = "some key";
        string memory jsonOjectToUpdate = vm.serializeAddress(obj1, "collectionAddress", _newAddress);

        vm.writeJson(jsonOjectToUpdate, jsonDataPath, jsonKey);
    }
}
