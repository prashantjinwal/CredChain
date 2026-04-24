// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CertVerifyBase} from "./CertVerifyBase.t.sol";
import {CertVerify} from "../src/CertVerify.sol";

/**
 * @title  GasBenchmarkTest
 * @notice Snapshot tests that document gas costs for critical operations.
 *         Run with `forge snapshot` to record baselines.
 *         CI should run `forge snapshot --check` to detect regressions.
 *
 * @dev    These are NOT correctness tests — they exist purely to surface
 *         unintended gas changes (e.g. accidentally enabling events twice,
 *         storage layout shifts, etc.).
 */
contract GasBenchmarkTest is CertVerifyBase {

    // ── setIssuerStatus ───────────────────────────────────────────────────────

    function test_gas_authorizeNewIssuer() public {
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerB, true);
    }

    function test_gas_deauthorizeIssuer() public {
        // issuerA is already authorized from setUp()
        vm.prank(superAdmin);
        cv.setIssuerStatus(issuerA, false);
    }

    // ── issueCertificate ──────────────────────────────────────────────────────

    function test_gas_issueCertificate() public {
        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, CID_1);
    }

    function test_gas_issueCertificateLongCID() public {
        string memory longCID = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdGQmYwAPJzv5CZsnA";
        vm.prank(issuerA);
        cv.issueCertificate(CERT_ID_1, recipientA, longCID);
    }

    // ── getCertificate ────────────────────────────────────────────────────────

    function test_gas_getCertificate() public {
        _issueCert1();
        cv.getCertificate(CERT_ID_1);
    }

    // ── revokeCertificate ─────────────────────────────────────────────────────

    function test_gas_revokeCertificate() public {
        _issueCert1();
        vm.prank(issuerA);
        cv.revokeCertificate(CERT_ID_1);
    }

    // ── tokenURI ──────────────────────────────────────────────────────────────

    function test_gas_tokenURI() public {
        _issueCert1();
        cv.tokenURI(CERT_ID_1);
    }
}
