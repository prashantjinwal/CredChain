// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CertVerifyBase} from "./CertVerifyBase.t.sol";
import {CertVerify} from "../src/CertVerify.sol";

/**
 * @title  RevocationTest
 * @notice Full coverage of revokeCertificate().
 *         Covers happy paths, all revert branches, event emission, and
 *         cross-issuer isolation.
 */
contract RevocationTest is CertVerifyBase {

    // ── Happy path ────────────────────────────────────────────────────────────

    function test_issuerCanRevokeOwnCert() public {
        _issueCert1();
        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);

        (,,, bool revoked,) = cv.getCertificate(CERT_ID_1);
        assertTrue(revoked);
    }

    function test_revokedCertStillExistsOnChain() public {
        _issueCert1();
        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);

        // Must not revert — the SBT is never burned
        (address issuer,,,, address holder) = cv.getCertificate(CERT_ID_1);
        assertEq(issuer, issuerA);
        assertEq(holder, recipientA);
    }

    function test_recipientStillHoldsTokenAfterRevocation() public {
        _issueCert1();
        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);

        assertEq(cv.ownerOf(CERT_ID_1), recipientA);
        assertEq(cv.balanceOf(recipientA), 1);
    }

    function test_twoIssuersRevokeTheirOwnCertsIndependently() public {
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerB, true);

        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, CID_1);

        vm.prank(issuerB);
        cv.issueCertificate(CERT_ID_2, recipientB, CID_2);

        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);

        (,,, bool revokedA,) = cv.getCertificate(CERT_ID_1);
        (,,, bool revokedB,) = cv.getCertificate(CERT_ID_2);

        assertTrue(revokedA);
        assertFalse(revokedB);
    }

    // ── Revert: CertificateNotFound ───────────────────────────────────────────

    function test_revertOnRevokeNonExistentCert() public {
        vm.prank(issuerA);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.CertificateNotFound.selector, 9999)
        );
        cv.revokeCertificate(9999);
    }

    // ── Revert: NotOriginalIssuer ─────────────────────────────────────────────

    function test_revertIfStrangerTriesToRevoke() public {
        _issueCert1();
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NotOriginalIssuer.selector, CERT_ID_1, stranger)
        );
        cv.revokeCertificate(CERT_ID_1);
    }

    function test_revertIfDifferentAuthorizedIssuerTriesToRevoke() public {
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerB, true);

        _issueCert1(); // Issued by issuerA

        vm.prank(issuerB);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NotOriginalIssuer.selector, CERT_ID_1, issuerB)
        );
        cv.revokeCertificate(CERT_ID_1);
    }

    function test_revertIfOwnerTriesToRevoke() public {
        _issueCert1();
        vm.prank(superAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NotOriginalIssuer.selector, CERT_ID_1, superAdmin)
        );
        cv.revokeCertificate(CERT_ID_1);
    }

    function test_revertIfRecipientTriesToRevoke() public {
        _issueCert1();
        vm.prank(recipientA);
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.NotOriginalIssuer.selector, CERT_ID_1, recipientA)
        );
        cv.revokeCertificate(CERT_ID_1);
    }

    // ── Revert: CertificateAlreadyRevoked ─────────────────────────────────────

    function test_revertOnDoubleRevoke() public {
        _issueCert1();
        vm.startPrank(issuerA);
        cv.revokeCertificate(CERT_ID_1);

        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.CertificateAlreadyRevoked.selector, CERT_ID_1)
        );
        cv.revokeCertificate(CERT_ID_1);
        vm.stopPrank();
    }

    // ── Access after deauthorization ──────────────────────────────────────────

    /**
     * @dev A deauthorized issuer can still revoke its own previously-minted
     *      certificates.  The revocation check is based on cert.issuer, not
     *      the live whitelist.  This test documents that design intent.
     */
    function test_deauthorizedIssuerCanStillRevokeOwnCert() public {
        _issueCert1();

        // Super admin removes issuerA from whitelist
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerA, false);
        assertFalse(cv.isAuthorizedIssuer(issuerA));

        // But issuerA can still revoke its own old certificate
        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1); // must NOT revert

        (,,, bool revoked,) = cv.getCertificate(CERT_ID_1);
        assertTrue(revoked);
    }

    // ── Events ────────────────────────────────────────────────────────────────

    function test_emitsCertificateRevokedEvent() public {
        _issueCert1();

        uint256 expectedTimestamp = block.timestamp;

        vm.expectEmit(true, true, false, true);
        emit CertVerify.CertificateRevoked(CERT_ID_1, issuerA, expectedTimestamp);

        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);
    }

    // ── Fuzz ──────────────────────────────────────────────────────────────────

    function testFuzz_onlyOriginalIssuerCanRevoke(address attacker) public {
        vm.assume(attacker != issuerA);
        _issueCert1();

        vm.prank(attacker);
        vm.expectRevert();
        cv.revokeCertificate(CERT_ID_1);
    }
}
