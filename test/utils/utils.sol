// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";

function bytes32ToString(bytes32 _bytes32) pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) i++;
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
}

function first(Vm.Log[] memory logs, bytes memory _event) pure returns (Vm.Log memory) {
    for (uint256 i = 0; i < logs.length; i++) {
        if (logs[i].topics[0] == keccak256(_event)) return logs[i];
    }
    revert(string.concat(string(_event), " not found"));
}

function asAddress(bytes32 b) pure returns (address) {
    return address(uint160(uint256(b)));
}

function fill(uint256 length, address a) pure returns (address[] memory addresses) {
    addresses = new address[](length);
    for (uint256 i = 0; i < length; ++i) {
        addresses[i] = a;
    }
}

function push(address[] calldata a, address b) pure returns (address[] memory addresses) {
    addresses = new address[](a.length + 1);
    for (uint256 i = 0; i < a.length; ++i) {
        addresses[i] = a[i];
    }
    addresses[a.length] = b;
}

function toArray(uint256 n, uint256 n2) pure returns (uint256[] memory arr) {
    arr = new uint256[](2);
    arr[0] = n;
    arr[1] = n2;
}

function toArray(uint256 n) pure returns (uint256[] memory arr) {
    arr = new uint256[](1);
    arr[0] = n;
}

function toArray(address a) pure returns (address[] memory arr) {
    arr = new address[](1);
    arr[0] = a;
}

function toStringArray(string memory a) pure returns (string[] memory arr) {
    arr = new string[](1);
    arr[0] = a;
}

function toArray(bytes memory a) pure returns (bytes[] memory arr) {
    arr = new bytes[](1);
    arr[0] = a;
}

function toArray(address a, address b) pure returns (address[] memory arr) {
    arr = new address[](2);
    arr[0] = a;
    arr[1] = b;
}

function toStringArray(string memory a, string memory b) pure returns (string[] memory arr) {
    arr = new string[](2);
    arr[0] = a;
    arr[1] = b;
}

function toArray(bytes memory a, bytes memory b) pure returns (bytes[] memory arr) {
    arr = new bytes[](2);
    arr[0] = a;
    arr[1] = b;
}
