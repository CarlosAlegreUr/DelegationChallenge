// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

function _getSelectorFromCalldata() pure returns (bytes4) {
    return bytes4(msg.data[:4]);
}
