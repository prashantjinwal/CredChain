// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CertVerifyBase} from "./CertVerifyBase.t.sol";
import {IERC721}         from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {CertVerify}      from "../src/CertVerify.sol";

/**
 * @title  SoulboundTest
 * @notice Exhaustive verification of the soulbound (non-transferable) property.
 *         Every possible ERC-721 movement vector is tested:
 *           • transferFrom
 *           • safeTransferFrom (both overloads)
 *           • approve + transferFrom by an approved operator
 *           • setApprovalForAll + transferFrom by an approved operator
 *         Mint and burn (if ever added) must remain unblocked.
 */
contract SoulboundTest is CertVerifyBase {

    function setUp() public override {
        super.setUp();
        _issueCert1(); // recipientA holds CERT_ID_1
    }

    // ── transferFrom variants ─────────────────────────────────────────────────

    function test_transferFromRevertsForHolder() public {
        vm.prank(recipientA);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NonTransferable.selector, CERT_ID_1)
        );
        cv.transferFrom(recipientA, recipientB, CERT_ID_1);
    }

    function test_transferFromRevertsForApprovedAddress() public {
        // recipientA approves stranger
        vm.prank(recipientA);
        cv.approve(stranger, CERT_ID_1);

        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NonTransferable.selector, CERT_ID_1)
        );
        cv.transferFrom(recipientA, recipientB, CERT_ID_1);
    }

    function test_transferFromRevertsForApprovedOperator() public {
        vm.prank(recipientA);
        cv.setApprovalForAll(stranger, true);

        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NonTransferable.selector, CERT_ID_1)
        );
        cv.transferFrom(recipientA, recipientB, CERT_ID_1);
    }

    // ── safeTransferFrom (no data) ────────────────────────────────────────────

    function test_safeTransferFromRevertsForHolder() public {
        vm.prank(recipientA);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NonTransferable.selector, CERT_ID_1)
        );
        cv.safeTransferFrom(recipientA, recipientB, CERT_ID_1);
    }

    function test_safeTransferFromRevertsForApprovedAddress() public {
        vm.prank(recipientA);
        cv.approve(stranger, CERT_ID_1);

        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NonTransferable.selector, CERT_ID_1)
        );
        cv.safeTransferFrom(recipientA, recipientB, CERT_ID_1);
    }

    // ── safeTransferFrom (with data) ──────────────────────────────────────────

    function test_safeTransferFromWithDataRevertsForHolder() public {
        vm.prank(recipientA);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NonTransferable.selector, CERT_ID_1)
        );
        cv.safeTransferFrom(recipientA, recipientB, CERT_ID_1, "0xdeadbeef");
    }

    // ── Owner stays constant ──────────────────────────────────────────────────

    function test_ownerUnchangedAfterFailedTransfer() public {
        vm.prank(recipientA);
        try cv.transferFrom(recipientA, recipientB, CERT_ID_1) {} catch {}
        assertEq(cv.ownerOf(CERT_ID_1), recipientA);
    }

    // ── approve() itself is not blocked (only the transfer is) ───────────────
    // OZ v5 allows approval but the transfer will always revert. This tests
    // that approve does not revert but the approval is meaningless.

    function test_approveDoesNotRevert() public {
        vm.prank(recipientA);
        cv.approve(stranger, CERT_ID_1); // must not revert
        assertEq(cv.getApproved(CERT_ID_1), stranger);
    }

    function test_setApprovalForAllDoesNotRevert() public {
        vm.prank(recipientA);
        cv.setApprovalForAll(stranger, true); // must not revert
        assertTrue(cv.isApprovedForAll(recipientA, stranger));
    }

    // ── Fuzz: no address can receive a transfer ───────────────────────────────

    function testFuzz_transferAlwaysReverts(address to) public {
        vm.assume(to != address(0));
        vm.prank(recipientA);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NonTransferable.selector, CERT_ID_1)
        );
        cv.transferFrom(recipientA, to, CERT_ID_1);
    }

    // ── Mint is still permitted (from == address(0)) ──────────────────────────

    function test_mintIsNotBlockedBySoulboundLock() public {
        // If mint reverted, issueCertificate would have reverted in setUp.
        // A second mint to a new ID confirms the lock only blocks transfers.
        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_2, recipientB, CID_2); // must not revert

        assertEq(cv.ownerOf(CERT_ID_2), recipientB);
    }
}
