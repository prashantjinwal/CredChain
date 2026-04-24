// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {CertVerify}        from "../src/CertVerify.sol";

/**
 * @title   Manage
 * @notice  Operational helper scripts for CertVerify administration.
 *          Each task is isolated as its own `run*` function so CI/CD
 *          pipelines can call exactly what they need.
 *
 * @dev     Usage examples
 *          ──────────────
 *          # Authorize a new issuer
 *          forge script script/Manage.s.sol:Manage \
 *              --sig "runAuthorizeIssuer(address,address)" \
 *              $CERT_VERIFY_ADDR $ISSUER_ADDR \
 *              --rpc-url $RPC_URL --broadcast -vvvv
 *
 *          # Revoke issuer access
 *          forge script script/Manage.s.sol:Manage \
 *              --sig "runDeauthorizeIssuer(address,address)" \
 *              $CERT_VERIFY_ADDR $ISSUER_ADDR \
 *              --rpc-url $RPC_URL --broadcast -vvvv
 *
 *          # Issue a certificate
 *          forge script script/Manage.s.sol:Manage \
 *              --sig "runIssueCertificate(address,uint256,address,string)" \
 *              $CERT_VERIFY_ADDR $CERT_ID $RECIPIENT "QmXxx..." \
 *              --rpc-url $RPC_URL --broadcast -vvvv
 *
 *          # Revoke a certificate
 *          forge script script/Manage.s.sol:Manage \
 *              --sig "runRevokeCertificate(address,uint256)" \
 *              $CERT_VERIFY_ADDR $CERT_ID \
 *              --rpc-url $RPC_URL --broadcast -vvvv
 *
 *          # Inspect a certificate (read-only, no broadcast needed)
 *          forge script script/Manage.s.sol:Manage \
 *              --sig "runInspectCertificate(address,uint256)" \
 *              $CERT_VERIFY_ADDR $CERT_ID \
 *              --rpc-url $RPC_URL -vvvv
 */
contract Manage is Script {

    // =========================================================================
    //  ADMIN — Issuer Whitelist
    // =========================================================================

    /**
     * @notice Grant issuer rights to `issuer`.
     * @dev    Caller must be the contract owner.  Set DEPLOYER_PRIVATE_KEY.
     */
    function runAuthorizeIssuer(
        address certVerifyAddr,
        address issuer
    ) external {
        CertVerify cv = CertVerify(certVerifyAddr);
        uint256 ownerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        console2.log("Authorizing issuer:", issuer);

        vm.startBroadcast(ownerKey);
        cv.setIssuerStatus(issuer, true);
        vm.stopBroadcast();

        require(cv.isAuthorizedIssuer(issuer), "Manage: auth failed");
        console2.log("Issuer authorized successfully");
    }

    /**
     * @notice Revoke issuer rights from `issuer`.
     * @dev    Caller must be the contract owner.  Set DEPLOYER_PRIVATE_KEY.
     */
    function runDeauthorizeIssuer(
        address certVerifyAddr,
        address issuer
    ) external {
        CertVerify cv = CertVerify(certVerifyAddr);
        uint256 ownerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        console2.log("Deauthorizing issuer:", issuer);

        vm.startBroadcast(ownerKey);
        cv.setIssuerStatus(issuer, false);
        vm.stopBroadcast();

        require(!cv.isAuthorizedIssuer(issuer), "Manage: deauth failed");
        console2.log("Issuer deauthorized successfully");
    }

    // =========================================================================
    //  ISSUANCE
    // =========================================================================

    /**
     * @notice Mint a soulbound certificate.
     * @dev    Caller must be an authorized issuer.  Set ISSUER_PRIVATE_KEY.
     *
     * @param certVerifyAddr  Deployed contract address.
     * @param certId          Deterministic certificate ID (pre-computed off-chain).
     * @param recipient       Learner's wallet.
     * @param ipfsCID         IPFS CID of the metadata JSON (no "ipfs://" prefix).
     */
    function runIssueCertificate(
        address certVerifyAddr,
        uint256 certId,
        address recipient,
        string  calldata ipfsCID
    ) external {
        CertVerify cv = CertVerify(certVerifyAddr);
        uint256 issuerKey = vm.envUint("ISSUER_PRIVATE_KEY");

        console2.log("Issuing certificate");
        console2.log("  CertID   :", certId);
        console2.log("  Recipient:", recipient);
        console2.log("  IPFS CID :", ipfsCID);

        vm.startBroadcast(issuerKey);
        cv.issueCertificate(certId, recipient, ipfsCID);
        vm.stopBroadcast();

        // Verify on-chain state
        (
            address returnedIssuer,
            string memory returnedCID,
            uint256 issuedAt,
            bool revoked,
            address holder
        ) = cv.getCertificate(certId);

        require(holder    == recipient,          "Manage: recipient mismatch");
        require(!revoked,                        "Manage: cert is revoked");
        require(returnedIssuer == vm.addr(issuerKey), "Manage: issuer mismatch");

        console2.log("Certificate issued successfully");
        console2.log("  Issuer  :", returnedIssuer);
        console2.log("  CID     :", returnedCID);
        console2.log("  IssuedAt:", issuedAt);
        console2.log("  Holder  :", holder);
    }

    // =========================================================================
    //  REVOCATION
    // =========================================================================

    /**
     * @notice Permanently revoke a certificate.
     * @dev    Caller must be the original issuer.  Set ISSUER_PRIVATE_KEY.
     */
    function runRevokeCertificate(
        address certVerifyAddr,
        uint256 certId
    ) external {
        CertVerify cv = CertVerify(certVerifyAddr);
        uint256 issuerKey = vm.envUint("ISSUER_PRIVATE_KEY");

        console2.log("Revoking certificate:", certId);

        vm.startBroadcast(issuerKey);
        cv.revokeCertificate(certId);
        vm.stopBroadcast();

        (,,, bool revoked,) = cv.getCertificate(certId);
        require(revoked, "Manage: revocation failed");
        console2.log("Certificate revoked successfully");
    }

    // =========================================================================
    //  INSPECTION (read-only)
    // =========================================================================

    /**
     * @notice Pretty-print all on-chain data for a certificate.
     * @dev    No broadcast needed — pure view calls.
     */
    function runInspectCertificate(
        address certVerifyAddr,
        uint256 certId
    ) external view {
        CertVerify cv = CertVerify(certVerifyAddr);

        (
            address issuer,
            string memory ipfsCID,
            uint256 issuedAt,
            bool revoked,
            address holder
        ) = cv.getCertificate(certId);

        console2.log("=== Certificate", certId, "===");
        console2.log("Issuer    :", issuer);
        console2.log("Holder    :", holder);
        console2.log("IPFS CID  :", ipfsCID);
        console2.log("Token URI :", cv.tokenURI(certId));
        console2.log("Issued At :", issuedAt);
        console2.log("Revoked   :", revoked);
    }

    // =========================================================================
    //  UTILITIES — deterministic certId computation (mirrors off-chain logic)
    // =========================================================================

    /**
     * @notice Compute the deterministic certId the backend would generate.
     * @dev    Call this to confirm the ID before embedding it in a QR code.
     */
    function computeCertId(
        address issuerWallet,
        address recipientWallet,
        uint256 courseId,
        uint256 issuanceTimestamp
    ) external pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            issuerWallet,
            recipientWallet,
            courseId,
            issuanceTimestamp
        )));
    }
}
