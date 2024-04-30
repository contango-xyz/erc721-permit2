// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721Permit2} from "src/interfaces/IERC721Permit2.sol";

library StructBuilder {
    function fillSigTransferDetails(uint256[] memory tokenIds, address[] memory tos)
        public
        pure
        returns (IERC721Permit2.SignatureTransferDetails[] memory transferDetails)
    {
        transferDetails = new IERC721Permit2.SignatureTransferDetails[](tos.length);
        for (uint256 i = 0; i < tos.length; ++i) {
            transferDetails[i] = IERC721Permit2.SignatureTransferDetails({to: tos[i], tokenId: tokenIds[i]});
        }
    }
}
