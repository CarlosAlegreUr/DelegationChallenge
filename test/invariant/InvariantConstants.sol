// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";

contract InvariantConstants is Test {
    uint256 public constant MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED = 1;
    address public immutable OWNS_NO_TOKENS_ADDRESS;
    address public immutable FALLBACK_ADDRESS_IF_RNDM_USER_INVALID;
    address public immutable SOME_ADDRESS;

    constructor() {
        OWNS_NO_TOKENS_ADDRESS = makeAddr("OWNS_NO_TOKENS");
        FALLBACK_ADDRESS_IF_RNDM_USER_INVALID = makeAddr("FALLBACK_ADDRESS_IF_RNDM_USER_INVALID");
        SOME_ADDRESS = makeAddr("SOME_ADDRESS");
    }
}
