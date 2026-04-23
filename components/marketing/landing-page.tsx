import Link from "next/link";

import { Brand } from "@/components/shared/brand";
import { ButtonLink, Panel, SubtleBadge } from "@/components/portal/shared";
import { formatCompactNumber, formatDate, shortHash } from "@/lib/format";
import type { PortalSnapshot } from "@/lib/portal-data";

const securityFeatures = [
  {
    title: "Immutable certificate proof",
    description: "Each credential gets a deterministic hash and chained block signature.",
  },
  {
    title: "Instant public verification",
    description: "Scan a QR or paste a certificate ID to confirm authenticity in seconds.",
  },
  {
    title: "Wallet-ready ownership",
    description: "Students can browse, preview, download, and share their credentials locally.",
  },
  {
    title: "Bulk issuance workflows",
    description: "Upload CSV batches, review mapping, and process certificates with queue visibility.",
  },
  {
    title: "Template-led presentation",
    description: "Manage branded certificate layouts for government and vocational programs.",
  },
  {
    title: "Operational analytics",
    description: "Track issuance velocity, course distribution, and institution performance.",
  },
];

const journeySteps = [
  {
    title: "Mint the certificate",
    description: "Institutes issue one credential or a batch through the secure dashboard.",
  },
  {
    title: "Hash and anchor",
    description: "CredChain generates SHA-256 proofs and appends each record to the JSON chain.",
  },
  {
    title: "Deliver to wallet",
    description: "Students open certificates with preview, QR code, and downloadable HTML.",
  },
  {
    title: "Verify anywhere",
    description: "Anyone can validate by scanning a QR code or entering the certificate ID.",
  },
];

const credentialTracks = [
  "Cloud Architecture",
  "Advanced Cyber Security",
  "Industrial Robotics",
  "Embedded Systems Design",
];

export function LandingPage({ snapshot }: { snapshot: PortalSnapshot }) {
  const featuredCertificate = snapshot.recentCertificates[0];

  return (
    <div className="page-shell mx-auto max-w-full overflow-hidden">
      <div className="px-6 pb-10 pt-6 md:px-10 md:pb-14">
        <header className="flex flex-col gap-5 border-b border-[color:var(--line)] pb-6 md:flex-row md:items-center md:justify-between">
          <Brand subtitle="Tamper-Proof Credentials" />
          <nav className="flex flex-wrap items-center gap-3 text-sm text-[#6E628C]">
            <Link href="#features" className="rounded-full px-3 py-2 transition hover:text-[#4F26DA]">
              Features
            </Link> 
            <Link href="#how-it-works" className="rounded-full px-3 py-2 transition hover:text-[#4F26DA]">
              How It Works
            </Link>
            <Link href="/verify" className="rounded-full px-3 py-2 transition hover:text-[#4F26DA]">
              Verify Certificate
            </Link>
            <Link href="/login" className="rounded-full px-3 py-2 transition hover:text-[#4F26DA]">
              Login
            </Link>
            <Link
              href="/portal"
              className="rounded-2xl bg-[#F5D1A2] px-5 py-3 font-semibold text-[#2A1659] transition hover:bg-[#edc48d]"
            >
              Get Started
            </Link>
          </nav>
        </header>

        <section className="soft-grid mt-8 overflow-hidden rounded-[36px] border border-[color:var(--line)] bg-[linear-gradient(135deg,#fffafc_0%,#f3ecff_100%)] px-6 py-8 md:px-10 md:py-12">
          <div className="grid gap-8 xl:grid-cols-[1.05fr,0.95fr] xl:items-center">
            <div className="space-y-7">
              <SubtleBadge>Trust protocol enabled</SubtleBadge>
              <div className="space-y-4">
                <h1 className="max-w-4xl text-5xl font-semibold leading-[0.95] tracking-tight text-[#25154F] md:text-7xl">
                  Tamper-Proof Skill <span className="brand-text-gradient">Credentials</span> on
                  Blockchain
                </h1>
                <p className="max-w-2xl text-lg leading-8 text-[#6E628C]">
                  Issue, verify, and own NCVET-style certificates instantly. CredChain brings
                  institutional dashboards, learner wallets, and public verification into one
                  elegant local workspace.
                </p>
              </div>
              <div className="flex flex-wrap items-center gap-4">
                <ButtonLink href="/portal/issue">Issue Certificate</ButtonLink>
                <ButtonLink href="/verify" tone="secondary">
                  Verify Certificate
                </ButtonLink>
              </div>
            </div>

            <Panel className="mx-auto max-w-[560px] rounded-[34px] bg-white/90 p-0">
              <div className="flex items-start justify-between border-b border-[color:var(--line)] px-8 py-6">
                <div className="space-y-3">
                  <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-100 text-[#4F26DA]">
                    <span className="text-xl font-semibold">S</span>
                  </div>
                  <div>
                    <p className="text-sm font-semibold uppercase tracking-[0.2em] text-[#8B79B9]">
                      Blockchain ID
                    </p>
                    <p className="mt-1 text-xs text-[#A493C3]">
                      {featuredCertificate
                        ? shortHash(featuredCertificate.blockHash, 12)
                        : "8c71c...a91d"}
                    </p>
                  </div>
                </div>
                <SubtleBadge tone="amber">Verified</SubtleBadge>
              </div>
              <div className="grid gap-8 px-8 py-8 md:grid-cols-[1fr,140px]">
                <div className="space-y-5">
                  <div>
                    <p className="text-3xl font-semibold text-[#2A1659]">
                      {featuredCertificate?.certificateTitle ?? "Master of Digital Architecture"}
                    </p>
                    <p className="mt-4 max-w-md leading-7 text-[#70648F]">
                      This is to certify that{" "}
                      {featuredCertificate?.studentName ?? "Rahul Sharma"} has successfully
                      completed the vocational training program at{" "}
                      {featuredCertificate?.instituteName ?? "NCVET Institute"}.
                    </p>
                  </div>
                  <div className="grid gap-4 md:grid-cols-2">
                    <div className="rounded-[22px] bg-violet-50 p-4">
                      <p className="text-[10px] font-semibold uppercase tracking-[0.22em] text-[#8B79B9]">
                        Issued date
                      </p>
                      <p className="mt-3 text-lg font-semibold text-[#2A1659]">
                        {featuredCertificate ? formatDate(featuredCertificate.issueDate) : "Oct 24, 2023"}
                      </p>
                    </div>
                    <div className="rounded-[22px] bg-violet-50 p-4">
                      <p className="text-[10px] font-semibold uppercase tracking-[0.22em] text-[#8B79B9]">
                        Ledger proof
                      </p>
                      <p className="mt-3 text-lg font-semibold text-[#2A1659]">
                        {featuredCertificate ? shortHash(featuredCertificate.certificateHash, 10) : "0x71c...91d"}
                      </p>
                    </div>
                  </div>
                </div>
                <div className="flex items-center justify-center rounded-[26px] border border-[color:var(--line)] bg-[#faf7ff] p-4">
                  <div className="flex h-28 w-28 items-center justify-center rounded-[20px] border-4 border-[#24154E] bg-[linear-gradient(135deg,#f0e8ff_0%,#ffffff_100%)] text-center text-[11px] font-semibold uppercase tracking-[0.18em] text-[#4F26DA]">
                    QR
                    <br />
                    Verify
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        </section>

        <section className="mt-8 grid gap-4 md:grid-cols-4">
          <Panel className="rounded-[28px] bg-white/82">
            <p className="text-3xl font-semibold text-[#2A1659]">
              {formatCompactNumber(snapshot.totalIssued)}
            </p>
            <p className="mt-2 text-sm text-[#6E628C]">Total credentials issued</p>
          </Panel>
          <Panel className="rounded-[28px] bg-white/82">
            <p className="text-3xl font-semibold text-[#2A1659]">
              {formatCompactNumber(snapshot.activeLearners)}
            </p>
            <p className="mt-2 text-sm text-[#6E628C]">Active learner records</p>
          </Panel>
          <Panel className="rounded-[28px] bg-white/82">
            <p className="text-3xl font-semibold text-[#2A1659]">
              {snapshot.verificationRate.toFixed(1)}%
            </p>
            <p className="mt-2 text-sm text-[#6E628C]">Verification confidence</p>
          </Panel>
          <Panel className="rounded-[28px] bg-white/82">
            <p className="text-3xl font-semibold text-[#2A1659]">
              {formatCompactNumber(snapshot.activeInstitutes)}
            </p>
            <p className="mt-2 text-sm text-[#6E628C]">Institutions onboarded locally</p>
          </Panel>
        </section>

        <section id="features" className="mt-16">
          <div className="text-center">
            <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[#8B79B9]">
              Uncompromising security features
            </p>
            <h2 className="mt-3 text-4xl font-semibold tracking-tight text-[#2A1659]">
              Everything an institute needs to issue and defend digital credentials.
            </h2>
          </div>
          <div className="mt-8 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
            {securityFeatures.map((feature) => (
              <Panel key={feature.title} className="bg-white/88">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-violet-100 text-lg font-semibold text-[#4F26DA]">
                  +
                </div>
                <h3 className="mt-6 text-2xl font-semibold text-[#271550]">{feature.title}</h3>
                <p className="mt-3 leading-7 text-[#6E628C]">{feature.description}</p>
              </Panel>
            ))}
          </div>
        </section>

        <section id="how-it-works" className="mt-16">
          <div className="text-center">
            <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[#8B79B9]">
              The 4-step journey
            </p>
            <h2 className="mt-3 text-4xl font-semibold tracking-tight text-[#2A1659]">
              From issuance to independent public verification.
            </h2>
          </div>
          <div className="mt-8 grid gap-5 md:grid-cols-2 xl:grid-cols-4">
            {journeySteps.map((step, index) => (
              <Panel key={step.title} className="bg-white/88">
                <div className="flex h-14 w-14 items-center justify-center rounded-2xl brand-gradient text-lg font-semibold text-white">
                  {index + 1}
                </div>
                <h3 className="mt-6 text-2xl font-semibold text-[#271550]">{step.title}</h3>
                <p className="mt-3 leading-7 text-[#6E628C]">{step.description}</p>
              </Panel>
            ))}
          </div>
        </section>

        <section className="mt-16 grid gap-6 lg:grid-cols-[1.1fr,0.9fr]">
          <Panel className="bg-white/86">
            <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[#8B79B9]">
              Credential tracks
            </p>
            <h2 className="mt-3 text-3xl font-semibold text-[#2A1659]">
              Built for vocational, academic, and technical programs.
            </h2>
            <div className="mt-6 grid gap-4 md:grid-cols-2">
              {credentialTracks.map((track) => (
                <div
                  key={track}
                  className="rounded-[22px] border border-[color:var(--line)] bg-[#faf7ff] px-5 py-4 text-sm font-semibold text-[#3D2A70]"
                >
                  {track}
                </div>
              ))}
            </div>
          </Panel>
          <Panel className="brand-gradient text-white">
            <p className="text-xs font-semibold uppercase tracking-[0.26em] text-white/60">
              Launch the portal
            </p>
            <h2 className="mt-3 text-3xl font-semibold">
              Ready to issue, verify, and manage your certificate ledger?
            </h2>
            <p className="mt-4 leading-8 text-white/80">
              Open the portal dashboard, publish your first credential, and keep the experience
              beautifully consistent from institute admin to learner wallet.
            </p>
            <div className="mt-8 flex flex-wrap gap-4">
              <Link
                href="/portal"
                className="rounded-2xl bg-white px-5 py-3 font-semibold text-[#4F26DA]"
              >
                Open dashboard
              </Link>
              <Link
                href="/login"
                className="rounded-2xl border border-white/20 px-5 py-3 font-semibold text-white"
              >
                Login
              </Link>
            </div>
          </Panel>
        </section>

        <footer className="mt-16 rounded-[28px] bg-[#26174B] px-6 py-10 text-white">
          <div className="grid gap-8 md:grid-cols-[1.2fr,0.8fr,0.8fr,0.8fr]">
            <div>
              <Brand dark subtitle="Verifiable Credential Network" />
              <p className="mt-5 max-w-sm leading-7 text-white/68">
                Local-first credential issuance and verification with an elegant interface modeled
                on modern education and compliance dashboards.
              </p>
            </div>
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.22em] text-white/50">
                Product
              </p>
              <div className="mt-4 space-y-3 text-white/70">
                <p>Features</p>
                <p>Security</p>
                <p>Analytics</p>
              </div>
            </div>
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.22em] text-white/50">
                Platform
              </p>
              <div className="mt-4 space-y-3 text-white/70">
                <p>Institution Portal</p>
                <p>Credential Wallet</p>
                <p>Verification</p>
              </div>
            </div>
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.22em] text-white/50">
                Quick access
              </p>
              <div className="mt-4 space-y-3 text-white/70">
                <p>Issue Certificate</p>
                <p>Verify</p>
                <p>Login</p>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
}
