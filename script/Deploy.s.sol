// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import {IERC721Permit2} from "src/interfaces/IERC721Permit2.sol";
import {ERC721Permit2} from "src/ERC721Permit2.sol";

contract Deploy is Script {
    bytes32 private constant SALT = keccak256("IERC721Permit2 0.0.1");

    function run() public {
        console.log("Deployment running, Network: %s", block.chainid);

        vm.broadcast();
        IERC721Permit2 deployed = new ERC721Permit2{salt: SALT}();
        console.log(StdStyle.red("IERC721Permit2 deployed at: %s"), address(deployed));
    }
}
