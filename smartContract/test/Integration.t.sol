// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CertVerifyBase} from "./CertVerifyBase.t.sol";
import {CertVerify} from "../src/CertVerify.sol";
/**
 * @title  IntegrationTest
 * @notice End-to-end lifecycle tests that chain multiple operations together
 *         and verify cumulative state, mirroring realistic production flows.
 */
contract IntegrationTest is CertVerifyBase {

    /**
     * @dev  Full happy path:
     *       1. Owner authorizes two issuers.
     *       2. Each issuer mints certs to different recipients.
     *       3. All certs are verifiable and valid.
     *       4. One cert is revoked; the other remains valid.
     *       5. Revoked cert still exists on-chain with correct holder.
     *       6. Transfers are always blocked.
     */
    function test_fullLifecycle() public {
        // ── 1. Authorize both issuers ─────────────────────────────────────────
        vm.startPrank(superAdmin);
        cv.setIssuerStatus(issuerA, true); // already done in setUp, idempotent
        cv.setIssuerStatus(issuerB, true);
        vm.stopPrank();

        // ── 2. Issue certificates ─────────────────────────────────────────────
        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, CID_1);

        vm.prank(issuerB);
        cv.issueCertificate(CERT_ID_2, recipientB, CID_2);

        // ── 3. Verify both certificates ───────────────────────────────────────
        {
            (address iss, string memory cid,,bool rev, address holder)
                = cv.getCertificate(CERT_ID_1);
            assertEq(iss,    issuerA);
            assertEq(cid,    CID_1);
            assertFalse(rev);
            assertEq(holder, recipientA);
        }
        {
            (address iss, string memory cid,,bool rev, address holder)
                = cv.getCertificate(CERT_ID_2);
            assertEq(iss,    issuerB);
            assertEq(cid,    CID_2);
            assertFalse(rev);
            assertEq(holder, recipientB);
        }

        // ── 4. Revoke cert 1 ──────────────────────────────────────────────────
        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);

        // ── 5. Post-revocation state ──────────────────────────────────────────
        (,,, bool revokedA, address holderA) = cv.getCertificate(CERT_ID_1);
        assertTrue(revokedA);
        assertEq(holderA, recipientA); // SBT persists

        (,,, bool revokedB,) = cv.getCertificate(CERT_ID_2);
        assertFalse(revokedB); // Cert 2 unaffected

        // ── 6. Transfer attempts always fail ─────────────────────────────────
        vm.prank(recipientA);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NonTransferable.selector, CERT_ID_1)
        );
        cv.transferFrom(recipientA, recipientB, CERT_ID_1);
    }

    /**
     * @dev  Issuer deauthorization + re-authorization cycle:
     *       • Deauthorized issuer cannot mint new certs.
     *       • Re-authorized issuer can mint again.
     *       • Old certs minted before deauthorization remain valid.
     */
    function test_issuerDeauthReauthCycle() public {
        // Issue while authorized
        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, CID_1);

        // Deauthorize
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerA, false);

        // Cannot mint after deauth
        vm.prank(issuerA);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NotAuthorizedIssuer.selector, issuerA)
        );
        cv.issueCertificate(CERT_ID_2, recipientB, CID_2);

        // Old cert still queryable
        (,,,, address holder) = cv.getCertificate(CERT_ID_1);
        assertEq(holder, recipientA);

        // Re-authorize
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerA, true);

        // Can mint again
        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_2, recipientB, CID_2); // must not revert
        assertEq(cv.ownerOf(CERT_ID_2), recipientB);
    }

    /**
     * @dev  Certid collision resistance: two issuers cannot both mint the
     *       same certId even when racing.
     */
    function test_certIdCollisionPrevention() public {
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerB, true);

        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, CID_1);

        // issuerB attempts same ID — must revert
        vm.prank(issuerB);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.CertificateAlreadyExists.selector, CERT_ID_1)
        );
        cv.issueCertificate(CERT_ID_1, recipientB, CID_2);
    }

    /**
     * @dev  Verifies that a recipient can hold many certificates from
     *       different issuers without conflicts.
     */
    function test_recipientHoldsMultipleFromDifferentIssuers() public {
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerB, true);

        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, CID_1);

        vm.prank(issuerB);
        cv.issueCertificate(CERT_ID_2, recipientA, CID_2);

        assertEq(cv.balanceOf(recipientA), 2);
        assertEq(cv.ownerOf(CERT_ID_1), recipientA);
        assertEq(cv.ownerOf(CERT_ID_2), recipientA);
    }

    /**
     * @dev  Ownership transfer of the contract (OZ Ownable):
     *       new owner can authorize issuers, old owner cannot.
     */
    function test_contractOwnershipTransfer() public {
        address newAdmin = makeAddr("newAdmin");

        vm.prank(superAdmin);
        cv.transferOwnership(newAdmin);

        // old admin can no longer authorize
        vm.prank(superAdmin);
        vm.expectRevert();
        cv.setIssuerStatus(issuerB, true);

        // new admin can authorize
        vm.prank(newAdmin);
        cv.setIssuerStatus(issuerB, true);
        assertTrue(cv.isAuthorizedIssuer(issuerB));
    }

    /**
     * @dev  Deterministic certId: the same inputs always produce the same
     *       ID so the backend can embed it in a QR code before confirmation.
     */
    function test_deterministicCertId() public pure {
        address _issuer    = address(0xABCD);
        address _recipient = address(0x1234);
        uint256 courseId   = 42;
        uint256 ts         = 1_700_000_000;

        uint256 id1 = uint256(keccak256(abi.encodePacked(_issuer, _recipient, courseId, ts)));
        uint256 id2 = uint256(keccak256(abi.encodePacked(_issuer, _recipient, courseId, ts)));

        assertEq(id1, id2);
    }
}
