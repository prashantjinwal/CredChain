// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ─────────────────────────────────────────────────────────────────────────────
//  INSTALL DEPS
//  npm install @openzeppelin/contracts@5
// ─────────────────────────────────────────────────────────────────────────────
import {ERC721}  from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title   CertVerify
 * @author  Fork It Technologies
 *
 * @notice  Global Truth Anchor for verifiable educational / professional
 *          certificates.  Each certificate is a Soulbound ERC-721 token —
 *          permanently tied to the recipient's wallet, non-transferable,
 *          and optionally revocable by the original issuer only.
 *
 * @dev     Design decisions
 *          ─────────────────
 *          • ERC-721 base (OpenZeppelin v5).
 *            tokenId  ==  deterministic CertID supplied by the off-chain
 *            Generator Service so the backend can embed the ID in QR codes
 *            and PDFs before the transaction is even confirmed.
 *
 *          • Hybrid storage: only the cryptographic proof lives on-chain.
 *            Full certificate metadata (name, course, grade, …) lives on
 *            IPFS and is linked via the stored CID.
 *
 *          • Soulbound lock: `_update()` — the single OZ-v5 hook covering
 *            every token movement — blocks all peer-to-peer transfers while
 *            still allowing mint and burn.
 *
 *          • Role-based access: Super Admin (contract owner) manages the
 *            Issuer Whitelist; only whitelisted organisations can mint.
 *
 *          • Checks-Effects-Interactions is strictly observed in every
 *            state-changing function.
 *
 *          • Custom errors replace revert strings throughout (~3-4x cheaper).
 */
contract CertVerify is ERC721, Ownable {

    // =========================================================================
    //  TYPES
    // =========================================================================

    /**
     * @dev On-chain certificate record.
     *      `ipfsCID` is stored WITHOUT the "ipfs://" prefix to save gas;
     *      `tokenURI()` prepends the prefix on read.
     */
    struct Certificate {
        address issuer;     // Authorized institute that minted this cert
        string  ipfsCID;    // IPFS CID for the full metadata JSON
        uint256 issuedAt;   // block.timestamp at mint time
        bool    revoked;    // One-way revocation flag (cannot be un-revoked)
    }

    // =========================================================================
    //  STATE
    // =========================================================================

    /// @dev certId (== ERC-721 tokenId) => Certificate record
    mapping(uint256 => Certificate) private _certificates;

    /// @dev issuer wallet => authorization status
    mapping(address => bool) private _authorizedIssuers;

    // =========================================================================
    //  EVENTS
    // =========================================================================

    /**
     * @notice Fires whenever the Super Admin changes an issuer's authorization.
     * @param issuer  Wallet of the organization.
     * @param status  true = authorized, false = deauthorized.
     */
    event IssuerStatusUpdated(address indexed issuer, bool status);

    /**
     * @notice Fires on every successful certificate mint.
     * @param certId     Deterministic certificate / token ID.
     * @param issuer     Authorized institute that called `issueCertificate`.
     * @param recipient  Learner's wallet that received the SBT.
     * @param ipfsCID    IPFS CID of the metadata JSON.
     * @param issuedAt   Block timestamp at issuance.
     */
    event CertificateIssued(
        uint256 indexed certId,
        address indexed issuer,
        address indexed recipient,
        string  ipfsCID,
        uint256 issuedAt
    );

    /**
     * @notice Fires when an issuer revokes one of its own certificates.
     * @param certId    The invalidated certificate ID.
     * @param issuer    The organization that triggered revocation.
     * @param revokedAt Block timestamp at revocation.
     */
    event CertificateRevoked(
        uint256 indexed certId,
        address indexed issuer,
        uint256 revokedAt
    );

    //  CUSTOM ERRORS
    /// Caller is not in the authorized-issuer whitelist.
    error NotAuthorizedIssuer(address caller);

    /// A certificate with this ID already exists on-chain.
    error CertificateAlreadyExists(uint256 certId);

    /// No certificate record found for the supplied ID.
    error CertificateNotFound(uint256 certId);

    /// Caller is not the original issuer of this certificate.
    error NotOriginalIssuer(uint256 certId, address caller);

    /// Certificate is already revoked; cannot revoke twice.
    error CertificateAlreadyRevoked(uint256 certId);

    /// Soulbound rule: peer-to-peer transfers are permanently blocked.
    error NonTransferable(uint256 tokenId);

    /// A zero-address was supplied where a valid address is required.
    error ZeroAddress();

    /// The `ipfsCID` argument was an empty string.
    error EmptyIPFSCID();

    //  CONSTRUCTOR
    /**
     * @param initialOwner  Wallet that becomes the Super Admin.
     *                      Pass `msg.sender` from your deployment script.
     */
    constructor(address initialOwner)
        ERC721("CertVerify Soulbound Certificate", "CVSC")
        Ownable(initialOwner)
    {}

    // =========================================================================
    //  A.  ADMINISTRATION — Issuer Whitelist
    // =========================================================================

    /**
     * @notice  Super Admin adds or removes an organization from the issuer
     *          whitelist.
     *
     * @dev     Restricted to the contract owner via `onlyOwner`.
     *          Emits {IssuerStatusUpdated}.
     *
     * @param issuer  Organization's wallet address.
     * @param status  true = authorize, false = deauthorize.
     */
    function setIssuerStatus(address issuer, bool status)
        external
        onlyOwner
    {
        if (issuer == address(0)) revert ZeroAddress();

        _authorizedIssuers[issuer] = status;

        emit IssuerStatusUpdated(issuer, status);
    }

    /**
     * @notice  Read-only check: is a given wallet an authorized issuer?
     * @param   issuer  Wallet to query.
     * @return          true if authorized.
     */
    function isAuthorizedIssuer(address issuer)
        external
        view
        returns (bool)
    {
        return _authorizedIssuers[issuer];
    }

    // =========================================================================
    //  B.  ISSUANCE — Mint a Soulbound Certificate
    // =========================================================================

    /**
     * @notice  Records a certificate on-chain and mints the SBT to the learner.
     *
     * @dev     The `certId` is a deterministic uint256 computed off-chain, e.g.:
     *
     *              certId = uint256(keccak256(abi.encodePacked(
     *                  issuerWallet,
     *                  recipientWallet,
     *                  courseId,
     *                  issuanceTimestamp
     *              )));
     *
     *          This lets your backend embed the ID in the PDF / QR code before
     *          the blockchain transaction is confirmed.
     *
     *          Checks-Effects-Interactions order is strictly followed:
     *            1. Checks      — auth, duplicate, zero-addr, empty CID.
     *            2. Effects     — write struct, emit event.
     *            3. Interaction — _safeMint (external call, last step).
     *
     *          Emits {CertificateIssued}.
     *
     * @param certId     Deterministic certificate ID (becomes ERC-721 tokenId).
     * @param recipient  Learner's wallet address.
     * @param ipfsCID    IPFS CID of the certificate metadata JSON.
     */
    function issueCertificate(
        uint256         certId,
        address         recipient,
        string calldata ipfsCID
    ) external {
        // ── 1. Checks ─────────────────────────────────────────────────────────
        if (!_authorizedIssuers[msg.sender])  revert NotAuthorizedIssuer(msg.sender);
        if (_certExists(certId))              revert CertificateAlreadyExists(certId);
        if (recipient == address(0))          revert ZeroAddress();
        if (bytes(ipfsCID).length == 0)       revert EmptyIPFSCID();

        // ── 2. Effects ────────────────────────────────────────────────────────
        _certificates[certId] = Certificate({
            issuer   : msg.sender,
            ipfsCID  : ipfsCID,
            issuedAt : block.timestamp,
            revoked  : false
        });

        emit CertificateIssued(certId, msg.sender, recipient, ipfsCID, block.timestamp);

        // ── 3. Interaction (external call last — CEI compliance) ──────────────
        _safeMint(recipient, certId);
    }

    // =========================================================================
    //  C.  VERIFICATION — Public Truth Check
    // =========================================================================

    /**
     * @notice  Returns the full on-chain proof for a certificate.
     *          Called by your Next.js API when an employer scans a QR code.
     *
     * @dev     Pure view — zero gas for off-chain callers.
     *          Reverts with {CertificateNotFound} for unknown / fake IDs so
     *          your API can map the revert to HTTP 404 cleanly.
     *
     * @param  certId   Certificate ID embedded in the QR code.
     * @return issuer   Wallet of the institute that minted it.
     * @return ipfsCID  IPFS CID for the full metadata JSON.
     * @return issuedAt Unix timestamp of issuance.
     * @return revoked  true if the issuer has invalidated this certificate.
     * @return holder   Current SBT holder (always == original recipient).
     */
    function getCertificate(uint256 certId)
        external
        view
        returns (
            address issuer,
            string  memory ipfsCID,
            uint256 issuedAt,
            bool    revoked,
            address holder
        )
    {
        if (!_certExists(certId)) revert CertificateNotFound(certId);

        Certificate storage cert = _certificates[certId];

        return (
            cert.issuer,
            cert.ipfsCID,
            cert.issuedAt,
            cert.revoked,
            ownerOf(certId)         // always == original recipient (soulbound)
        );
    }

    // =========================================================================
    //  D.  INTEGRITY — Revocation
    // =========================================================================

    /**
     * @notice  Permanently marks a certificate as revoked.
     *          Only the *original issuer* of the specific certificate may call
     *          this — a different authorized institute cannot revoke another
     *          institute's certificates.
     *
     * @dev     Revocation is one-way: there is deliberately no `unrevoke`.
     *          The SBT is NOT burned so the on-chain audit trail is preserved.
     *          Emits {CertificateRevoked}.
     *
     * @param certId  Certificate ID to invalidate.
     */
    function revokeCertificate(uint256 certId) external {
        if (!_certExists(certId))         revert CertificateNotFound(certId);

        Certificate storage cert = _certificates[certId];

        if (cert.issuer != msg.sender)    revert NotOriginalIssuer(certId, msg.sender);
        if (cert.revoked)                 revert CertificateAlreadyRevoked(certId);

        cert.revoked = true;

        emit CertificateRevoked(certId, msg.sender, block.timestamp);
    }

    // =========================================================================
    //  SOULBOUND LOCK — Block Peer-to-Peer Transfers
    // =========================================================================

    /**
     * @dev     OpenZeppelin v5 replaced `_beforeTokenTransfer` with a single
     *          `_update(to, tokenId, auth)` hook that governs every token state
     *          change: mint, transfer, and burn.
     *
     *          Transfer decision matrix:
     *            from == address(0)              → Mint     → ALLOW
     *            to   == address(0)              → Burn     → ALLOW
     *            from != address(0) && to != 0   → Transfer → REJECT
     *
     *          Intercepting here neutralizes transferFrom, safeTransferFrom,
     *          and approve at the root level — no individual overrides needed.
     *
     * @param to       Destination address.
     * @param tokenId  Token being moved.
     * @param auth     Address validated as an approved operator by OZ internals.
     * @return         Previous owner address (passed through from super).
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId); // address(0) when token not yet minted

        if (from != address(0) && to != address(0)) {
            revert NonTransferable(tokenId);
        }

        return super._update(to, tokenId, auth);
    }

    // =========================================================================
    //  TOKEN URI — ERC-721 Metadata Standard
    // =========================================================================

    /**
     * @notice  Returns the full IPFS URI for a certificate's metadata JSON.
     * @dev     Format: `ipfs://<CID>` — compatible with OpenSea and all
     *          standard ERC-721 metadata resolvers.
     * @param   certId  Token / certificate ID to query.
     * @return          Full IPFS URI string.
     */
    function tokenURI(uint256 certId)
        public
        view
        override
        returns (string memory)
    {
        if (!_certExists(certId)) revert CertificateNotFound(certId);
        return string(abi.encodePacked("ipfs://", _certificates[certId].ipfsCID));
    }

    // =========================================================================
    //  INTERNAL HELPERS
    // =========================================================================

    /**
     * @dev  OZ v5 removed the `_exists()` utility.
     *       A token exists iff `_ownerOf` returns a non-zero address.
     *       Using `private` instead of `internal` since no child contract
     *       should need to override existence semantics.
     */
    function _certExists(uint256 certId) private view returns (bool) {
        return _ownerOf(certId) != address(0);
    }
}
