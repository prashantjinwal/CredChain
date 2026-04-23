import { BellIcon, SearchIcon } from "@/components/shared/icons";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export function PortalTopbar() {
  return (
    <div className="flex flex-col gap-4 border-b border-[color:var(--line)] pb-5 md:flex-row md:items-center md:justify-between">
      <div>
        <p className="text-sm font-semibold uppercase tracking-[0.24em] text-[#8B79B9]">
          NCVET Training Institute
        </p>
        <p className="mt-2 text-sm text-[#6E628C]">
          Operate issuance, wallet, verification, and analytics from one secure workspace.
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-3 rounded-2xl border border-[color:var(--line)] bg-white px-4 py-3 text-sm text-[#7A6C9C]">
          <SearchIcon className="h-4 w-4 text-[#8B79B9]" />
          Search learner or certificate
        </div>
        <button
          type="button"
          className="flex h-11 w-11 items-center justify-center rounded-2xl border border-[color:var(--line)] bg-white text-[#5B2EE6]"
          aria-label="Notifications"
        >
          <BellIcon className="h-5 w-5" />
        </button>
        <div
       >
            <ConnectButton/>
        </div>
        <div className="flex items-center gap-3 rounded-2xl border border-[color:var(--line)] bg-white px-3 py-2">
          <div className="flex h-10 w-10 items-center justify-center rounded-2xl brand-gradient text-sm font-semibold text-white">
            AP
          </div>
          <div>
            <p className="text-sm font-semibold text-[#2A1659]">Admin Portal</p>
            <p className="text-xs text-[#8B79B9]">Ashna Patel</p>
          </div>
        </div>
      </div>
    </div>
  );
}
