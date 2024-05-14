// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";

import "src/ERC721Permit2.sol";
import "./utils/PermitSignature.sol";
import "./utils/StructBuilder.sol";
import "./utils/ERC721Mock.sol";
import "./utils/utils.sol";

contract ERC721SafePermit2Test is Test, PermitSignature {
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);
    event Transfer(address indexed from, address indexed token, address indexed to, uint256 amount);

    ERC721Permit2 permit2;

    address from;
    uint256 fromPrivateKey;

    address address1 = address(new SafeReceiver());
    address address2 = address(new SafeReceiver());

    ERC721Mock token0;
    ERC721Mock token1;

    uint256 id1 = 1;
    uint256 id2 = 2;

    bytes32 DOMAIN_SEPARATOR;

    function setUp() public {
        permit2 = new ERC721Permit2();
        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();

        (from, fromPrivateKey) = makeAddrAndKey("from");

        token0 = new ERC721Mock("token0", "T0");
        token1 = new ERC721Mock("token1", "T1");

        token0.mint(address(from), id1);
        token0.mint(address(from), id2);
        token1.mint(address(from), id1);
        token1.mint(address(from), id2);

        vm.startPrank(from);
        token0.setApprovalForAll(address(permit2), true);
        token1.setApprovalForAll(address(permit2), true);
        vm.stopPrank();
    }

    function getTransferDetails(address to, uint256 tokenId)
        private
        pure
        returns (IERC721Permit2.SignatureTransferDetails memory)
    {
        return IERC721Permit2.SignatureTransferDetails(to, tokenId);
    }

    function testPermitSafeTransferFrom() public {
        uint256 nonce = 0;
        IERC721Permit2.PermitTransferFrom memory permit = defaultERC721PermitTransfer(address(token0), nonce, id1);
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        uint256 startBalanceFrom = token0.balanceOf(from);
        uint256 startBalanceTo = token0.balanceOf(address2);

        IERC721Permit2.SignatureTransferDetails memory transferDetails = getTransferDetails(address2, id1);

        permit2.permitSafeTransferFrom(permit, transferDetails, from, sig);

        assertEq(token0.balanceOf(from), startBalanceFrom - 1);
        assertEq(token0.balanceOf(address2), startBalanceTo + 1);
        assertEq(token0.ownerOf(id1), address2);
    }

    function testPermitSafeTransferFrom_FailOnUnsafeReceiver() public {
        address2 = address(new UnsafeReceiver());

        uint256 nonce = 0;
        IERC721Permit2.PermitTransferFrom memory permit = defaultERC721PermitTransfer(address(token0), nonce, id1);
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        IERC721Permit2.SignatureTransferDetails memory transferDetails = getTransferDetails(address2, id1);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address2));
        permit2.permitSafeTransferFrom(permit, transferDetails, from, sig);
    }

    function testPermitTransferFromCompactSig() public {
        uint256 nonce = 0;
        IERC721Permit2.PermitTransferFrom memory permit = defaultERC721PermitTransfer(address(token0), nonce, id1);
        bytes memory sig = getCompactPermitTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);
        assertEq(sig.length, 64);

        uint256 startBalanceFrom = token0.balanceOf(from);
        uint256 startBalanceTo = token0.balanceOf(address2);

        IERC721Permit2.SignatureTransferDetails memory transferDetails = getTransferDetails(address2, id1);

        permit2.permitSafeTransferFrom(permit, transferDetails, from, sig);

        assertEq(token0.balanceOf(from), startBalanceFrom - 1);
        assertEq(token0.balanceOf(address2), startBalanceTo + 1);
        assertEq(token0.ownerOf(id1), address2);
    }

    function testPermitTransferFromIncorrectSigLength() public {
        uint256 nonce = 0;
        IERC721Permit2.PermitTransferFrom memory permit = defaultERC721PermitTransfer(address(token0), nonce, id1);
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);
        bytes memory sigExtra = bytes.concat(sig, bytes1(uint8(0)));
        assertEq(sigExtra.length, 66);

        IERC721Permit2.SignatureTransferDetails memory transferDetails = getTransferDetails(address2, id1);

        vm.expectRevert(SignatureVerification.InvalidSignatureLength.selector);
        permit2.permitSafeTransferFrom(permit, transferDetails, from, sigExtra);
    }

    function testPermitTransferFromToSpender() public {
        uint256 nonce = 0;
        // signed spender is address(this)
        IERC721Permit2.PermitTransferFrom memory permit = defaultERC721PermitTransfer(address(token0), nonce, id1);
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        uint256 startBalanceFrom = token0.balanceOf(from);
        uint256 startBalanceTo = token0.balanceOf(address1);

        IERC721Permit2.SignatureTransferDetails memory transferDetails = getTransferDetails(address1, id1);

        permit2.permitSafeTransferFrom(permit, transferDetails, from, sig);

        assertEq(token0.balanceOf(from), startBalanceFrom - 1);
        assertEq(token0.balanceOf(address1), startBalanceTo + 1);
        assertEq(token0.ownerOf(id1), address1);
    }

    function testPermitTransferFromInvalidNonce() public {
        uint256 nonce = 0;
        IERC721Permit2.PermitTransferFrom memory permit = defaultERC721PermitTransfer(address(token0), nonce, id1);
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        IERC721Permit2.SignatureTransferDetails memory transferDetails = getTransferDetails(address2, id1);
        permit2.permitSafeTransferFrom(permit, transferDetails, from, sig);

        vm.expectRevert(IERC721Permit2.InvalidNonce.selector);
        permit2.permitSafeTransferFrom(permit, transferDetails, from, sig);
    }

    function testPermitTransferFromRandomNonceAndAmount(uint256 nonce, uint128 tokenId) public {
        vm.assume(tokenId > 0);
        if (tokenId > id2) token0.mint(address(from), tokenId);
        IERC721Permit2.PermitTransferFrom memory permit = defaultERC721PermitTransfer(address(token0), nonce, id1);
        permit.permitted.tokenId = tokenId;
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        uint256 startBalanceFrom = token0.balanceOf(from);
        uint256 startBalanceTo = token0.balanceOf(address2);
        IERC721Permit2.SignatureTransferDetails memory transferDetails = getTransferDetails(address2, tokenId);

        permit2.permitSafeTransferFrom(permit, transferDetails, from, sig);

        assertEq(token0.balanceOf(from), startBalanceFrom - 1);
        assertEq(token0.balanceOf(address2), startBalanceTo + 1);
        assertEq(token0.ownerOf(tokenId), address2);
    }

    function testPermitBatchTransferFrom_FailOnUnsafeReceiver() public {
        address2 = address(new UnsafeReceiver());

        uint256 nonce = 0;
        address[] memory tokens = toArray(address(token0), address(token1));
        uint256[] memory tokenIds = toArray(id1, id2);
        address[] memory to = toArray(address(address2), address(address1));

        IERC721Permit2.PermitBatchTransferFrom memory permit = defaultERC721PermitMultiple(tokens, nonce, tokenIds);
        bytes memory sig = getPermitBatchTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        IERC721Permit2.SignatureTransferDetails[] memory toAmountPairs =
            StructBuilder.fillSigTransferDetails(tokenIds, to);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address2));
        permit2.permitSafeTransferFrom(permit, toAmountPairs, from, sig);
    }

    function testPermitBatchTransferFrom() public {
        uint256 nonce = 0;
        address[] memory tokens = toArray(address(token0), address(token1));
        uint256[] memory tokenIds = toArray(id1, id2);
        address[] memory to = toArray(address(address2), address(address1));

        IERC721Permit2.PermitBatchTransferFrom memory permit = defaultERC721PermitMultiple(tokens, nonce, tokenIds);
        bytes memory sig = getPermitBatchTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        IERC721Permit2.SignatureTransferDetails[] memory toAmountPairs =
            StructBuilder.fillSigTransferDetails(tokenIds, to);

        uint256 startBalanceFrom0 = token0.balanceOf(from);
        uint256 startBalanceFrom1 = token1.balanceOf(from);
        uint256 startBalanceTo0 = token0.balanceOf(address2);
        uint256 startBalanceTo1 = token1.balanceOf(address1);

        permit2.permitSafeTransferFrom(permit, toAmountPairs, from, sig);

        assertEq(token0.balanceOf(from), startBalanceFrom0 - 1);
        assertEq(token1.balanceOf(from), startBalanceFrom1 - 1);
        assertEq(token0.balanceOf(address2), startBalanceTo0 + 1);
        assertEq(token1.balanceOf(address1), startBalanceTo1 + 1);

        assertEq(token0.ownerOf(id1), address2);
        assertEq(token1.ownerOf(id2), address1);
    }

    function testPermitBatchTransferFromSingleRecipient() public {
        uint256 nonce = 0;
        address[] memory tokens = toArray(address(token0), address(token1));
        uint256[] memory tokenIds = toArray(id1, id1);
        address[] memory to = toArray(address(address2), address(address2));

        IERC721Permit2.PermitBatchTransferFrom memory permit = defaultERC721PermitMultiple(tokens, nonce, tokenIds);
        bytes memory sig = getPermitBatchTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        IERC721Permit2.SignatureTransferDetails[] memory toAmountPairs =
            StructBuilder.fillSigTransferDetails(tokenIds, to);

        uint256 startBalanceFrom0 = token0.balanceOf(from);
        uint256 startBalanceFrom1 = token1.balanceOf(from);
        uint256 startBalanceTo0 = token0.balanceOf(address2);
        uint256 startBalanceTo1 = token1.balanceOf(address2);

        permit2.permitSafeTransferFrom(permit, toAmountPairs, from, sig);

        assertEq(token0.balanceOf(from), startBalanceFrom0 - 1);
        assertEq(token1.balanceOf(from), startBalanceFrom1 - 1);
        assertEq(token0.balanceOf(address2), startBalanceTo0 + 1);
        assertEq(token1.balanceOf(address2), startBalanceTo1 + 1);

        assertEq(token0.ownerOf(id1), address2);
        assertEq(token1.ownerOf(id1), address2);
    }

    function testPermitBatchTransferMultiAddr() public {
        uint256 nonce = 0;

        address[] memory tokens = toArray(address(token0), address(token1));
        uint256[] memory tokenIds = toArray(id1, id1);
        address[] memory to = toArray(address(this), address(address2));

        // signed spender is address(this)
        IERC721Permit2.PermitBatchTransferFrom memory permit = defaultERC721PermitMultiple(tokens, nonce, tokenIds);
        bytes memory sig = getPermitBatchTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        uint256 startBalanceFrom0 = token0.balanceOf(from);
        uint256 startBalanceFrom1 = token1.balanceOf(from);
        uint256 startBalanceTo0 = token0.balanceOf(address(this));
        uint256 startBalanceTo1 = token1.balanceOf(address2);

        IERC721Permit2.SignatureTransferDetails[] memory toAmountPairs =
            StructBuilder.fillSigTransferDetails(tokenIds, to);
        permit2.permitSafeTransferFrom(permit, toAmountPairs, from, sig);

        assertEq(token0.balanceOf(from), startBalanceFrom0 - 1);
        assertEq(token0.balanceOf(address(this)), startBalanceTo0 + 1);

        assertEq(token1.balanceOf(from), startBalanceFrom1 - 1);
        assertEq(token1.balanceOf(address2), startBalanceTo1 + 1);

        assertEq(token0.ownerOf(id1), address(this));
        assertEq(token1.ownerOf(id1), address2);
    }

    function testPermitBatchTransferSingleRecipientManyTokens() public {
        uint256 nonce = 0;

        address[] memory tokens = fill(10, address(token0));
        address[] memory to = fill(10, address(this));
        uint256[] memory tokenIds = new uint256[](10);
        for (uint256 i = 1; i <= 10; i++) {
            if (i > 2) token0.mint(address(from), i);
            tokenIds[i - 1] = i;
        }

        IERC721Permit2.PermitBatchTransferFrom memory permit = defaultERC721PermitMultiple(tokens, nonce, tokenIds);
        bytes memory sig = getPermitBatchTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        uint256 startBalanceFrom0 = token0.balanceOf(from);
        uint256 startBalanceTo0 = token0.balanceOf(address(this));

        IERC721Permit2.SignatureTransferDetails[] memory toAmountPairs =
            StructBuilder.fillSigTransferDetails(tokenIds, to);

        permit2.permitSafeTransferFrom(permit, toAmountPairs, from, sig);

        assertEq(token0.balanceOf(from), startBalanceFrom0 - 10);
        assertEq(token0.balanceOf(address(this)), startBalanceTo0 + 10);

        for (uint256 i = 1; i <= 10; i++) {
            assertEq(token0.ownerOf(i), address(this));
        }
    }

    function testPermitBatchTransferInvalidAmountsLengthMismatch() public {
        uint256 nonce = 0;

        address[] memory tokens = fill(2, address(token0));
        uint256[] memory tokenIds = toArray(id1, id2);
        address[] memory to = toArray(address(this));

        IERC721Permit2.PermitBatchTransferFrom memory permit = defaultERC721PermitMultiple(tokens, nonce, tokenIds);
        bytes memory sig = getPermitBatchTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        IERC721Permit2.SignatureTransferDetails[] memory toAmountPairs =
            StructBuilder.fillSigTransferDetails(tokenIds, to);

        vm.expectRevert(IERC721Permit2.LengthMismatch.selector);
        permit2.permitSafeTransferFrom(permit, toAmountPairs, from, sig);
    }

    function testInvalidateUnorderedNonces() public {
        IERC721Permit2.PermitTransferFrom memory permit = defaultERC721PermitTransfer(address(token0), 0, id1);
        bytes memory sig = getPermitTransferSignature(permit, fromPrivateKey, DOMAIN_SEPARATOR);

        uint256 bitmap = permit2.nonceBitmap(from, 0);
        assertEq(bitmap, 0);

        vm.prank(from);
        vm.expectEmit(true, false, false, true);
        emit UnorderedNonceInvalidation(from, 0, 1);
        permit2.invalidateUnorderedNonces(0, 1);
        bitmap = permit2.nonceBitmap(from, 0);
        assertEq(bitmap, 1);

        IERC721Permit2.SignatureTransferDetails memory transferDetails = getTransferDetails(address2, id1);

        vm.expectRevert(IERC721Permit2.InvalidNonce.selector);
        permit2.permitSafeTransferFrom(permit, transferDetails, from, sig);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract SafeReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract UnsafeReceiver {}
