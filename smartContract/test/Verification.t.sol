// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CertVerifyBase} from "./CertVerifyBase.t.sol";
import {CertVerify} from "../src/CertVerify.sol";

/**
 * @title  VerificationTest
 * @notice Full coverage of getCertificate() and tokenURI().
 */
contract VerificationTest is CertVerifyBase {

    // ── getCertificate ────────────────────────────────────────────────────────

    function test_getCertReturnsCorrectIssuer() public {
        _issueCert1();
        (address issuer,,,,) = cv.getCertificate(CERT_ID_1);
        assertEq(issuer, issuerA);
    }

    function test_getCertReturnsCorrectCID() public {
        _issueCert1();
        (, string memory cid,,,) = cv.getCertificate(CERT_ID_1);
        assertEq(cid, CID_1);
    }

    function test_getCertReturnsCorrectIssuedAt() public {
        uint256 warpTo = 1_710_000_000;
        vm.warp(warpTo);
        _issueCert1();
        (,, uint256 issuedAt,,) = cv.getCertificate(CERT_ID_1);
        assertEq(issuedAt, warpTo);
    }

    function test_getCertNotRevokedAfterMint() public {
        _issueCert1();
        (,,, bool revoked,) = cv.getCertificate(CERT_ID_1);
        assertFalse(revoked);
    }

    function test_getCertReturnsCorrectHolder() public {
        _issueCert1();
        (,,,, address holder) = cv.getCertificate(CERT_ID_1);
        assertEq(holder, recipientA);
    }

    function test_getCertRevokedAfterRevocation() public {
        _issueCert1();
        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);

        (,,, bool revoked,) = cv.getCertificate(CERT_ID_1);
        assertTrue(revoked);
    }

    // The holder stays the same even after revocation (SBT is not burned)
    function test_getCertHolderUnchangedAfterRevocation() public {
        _issueCert1();
        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);

        (,,,, address holder) = cv.getCertificate(CERT_ID_1);
        assertEq(holder, recipientA);
    }

    // ── getCertificate reverts ────────────────────────────────────────────────

    function test_getCertRevertsForUnknownId() public {
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.CertificateNotFound.selector, 9999)
        );
        cv.getCertificate(9999);
    }

    function test_getCertRevertsForIdZero() public {
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.CertificateNotFound.selector, 0)
        );
        cv.getCertificate(0);
    }

    // Anyone can call getCertificate — it is public view
    function test_anyoneCanVerifyCertificate() public {
        _issueCert1();
        vm.prank(stranger);
        (address issuer,,,, address holder) = cv.getCertificate(CERT_ID_1);
        assertEq(issuer, issuerA);
        assertEq(holder, recipientA);
    }

    // ── tokenURI ──────────────────────────────────────────────────────────────

    function test_tokenURIFormat() public {
        _issueCert1();
        string memory uri = cv.tokenURI(CERT_ID_1);
        assertEq(uri, string(abi.encodePacked("ipfs://", CID_1)));
    }

    function test_tokenURIPrefixIsIPFS() public {
        _issueCert1();
        string memory uri = cv.tokenURI(CERT_ID_1);
        // Verify the "ipfs://" prefix is present
        bytes memory b = bytes(uri);
        assertEq(b[0], "i");
        assertEq(b[1], "p");
        assertEq(b[2], "f");
        assertEq(b[3], "s");
        assertEq(b[4], ":");
        assertEq(b[5], "/");
        assertEq(b[6], "/");
    }

    function test_tokenURIRevertsForUnknownId() public {
        vm.expectRevert(
            abi.encodeWithSelector(CertVerify.CertificateNotFound.selector, 42)
        );
        cv.tokenURI(42);
    }

    function test_tokenURICorrectForMultipleCerts() public {
        vm.startPrank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, CID_1);
        cv.issueCertificate(CERT_ID_2, recipientB, CID_2);
        vm.stopPrank();

        assertEq(cv.tokenURI(CERT_ID_1), string(abi.encodePacked("ipfs://", CID_1)));
        assertEq(cv.tokenURI(CERT_ID_2), string(abi.encodePacked("ipfs://", CID_2)));
    }
}
