// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {CertVerify}        from "../src/CertVerify.sol";

/**
 * @title   Deploy
 * @notice  Primary deployment script for CertVerify.
 *
 * @dev     Usage
 *          ──────
 *          # Dry-run (no broadcast, uses Anvil default account)
 *          forge script script/Deploy.s.sol --rpc-url http://localhost:8545 -vvvv
 *
 *          # Live broadcast to a testnet (e.g. Sepolia)
 *          forge script script/Deploy.s.sol \
 *              --rpc-url $SEPOLIA_RPC_URL    \
 *              --broadcast                   \
 *              --verify                      \
 *              --etherscan-api-key $ETHERSCAN_KEY \
 *              -vvvv
 *
 *          Environment variables
 *          ──────────────────────
 *          DEPLOYER_PRIVATE_KEY  — deployer's private key (hex, with 0x prefix)
 *          INITIAL_OWNER         — (optional) override super-admin wallet.
 *                                  Defaults to vm.envAddress("INITIAL_OWNER")
 *                                  or falls back to the deployer itself.
 */
contract Deploy is Script {

    // ── Storage for post-deploy assertions ───────────────────────────────────
    CertVerify public certVerify;

    function run() external returns (CertVerify) {
        // ── 1. Load deployer key ─────────────────────────────────────────────
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        // ── 2. Resolve initial owner (defaults to deployer if not set) ───────
        address initialOwner;
        try vm.envAddress("INITIAL_OWNER") returns (address owner) {
            initialOwner = owner == address(0) ? deployer : owner;
        } catch {
            initialOwner = deployer;
        }

        console2.log("=== CertVerify Deployment ===");
        console2.log("Deployer     :", deployer);
        console2.log("Initial Owner:", initialOwner);

        // ── 3. Broadcast ─────────────────────────────────────────────────────
        vm.startBroadcast(deployerKey);

        certVerify = new CertVerify(initialOwner);

        vm.stopBroadcast();

        // ── 4. Post-deploy assertions (run off-chain, zero gas) ───────────────
        require(
            certVerify.owner() == initialOwner,
            "Deploy: owner mismatch"
        );
        require(
            keccak256(bytes(certVerify.name())) ==
                keccak256(bytes("CertVerify Soulbound Certificate")),
            "Deploy: name mismatch"
        );
        require(
            keccak256(bytes(certVerify.symbol())) == keccak256(bytes("CVSC")),
            "Deploy: symbol mismatch"
        );

        console2.log("CertVerify deployed at:", address(certVerify));
        console2.log("=== Deployment complete ===");

        return certVerify;
    }
}
