// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {CertVerify}      from "../src/CertVerify.sol";

/**
 * @title  CertVerifyBase
 * @notice Shared test fixtures and helpers used across all test contracts.
 *         Inheriting from `Test` lets every child call vm.*, deal(), etc.
 */
abstract contract CertVerifyBase is Test {

    // ── Actors ────────────────────────────────────────────────────────────────
    address internal superAdmin  = makeAddr("superAdmin");
    address internal issuerA     = makeAddr("issuerA");
    address internal issuerB     = makeAddr("issuerB");
    address internal recipientA  = makeAddr("recipientA");
    address internal recipientB  = makeAddr("recipientB");
    address internal stranger    = makeAddr("stranger");

    // ── Fixtures ──────────────────────────────────────────────────────────────
    CertVerify internal cv;

    /// Pre-computed deterministic cert IDs used in tests.
    uint256 internal constant CERT_ID_1  = uint256(keccak256("cert1"));
    uint256 internal constant CERT_ID_2  = uint256(keccak256("cert2"));
    uint256 internal constant CERT_ID_3  = uint256(keccak256("cert3"));

    string  internal constant CID_1 = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG";
    string  internal constant CID_2 = "QmSoLPppuBtQSGwKDZT2M73ULpjvfu6dvpHBHCBVot2GfX";

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    function setUp() public virtual {
        vm.prank(superAdmin);
        cv = new CertVerify(superAdmin);

        // Pre-authorize issuerA for convenience in most tests.
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerA, true);
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    /// Issue cert CERT_ID_1 from issuerA to recipientA (happy-path shortcut).
    function _issueCert1() internal {
        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, CID_1);
    }

    /// Compute certId the same way the off-chain backend would.
    function _computeCertId(
        address _issuer,
        address _recipient,
        uint256 courseId,
        uint256 ts
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_issuer, _recipient, courseId, ts)));
    }
}
