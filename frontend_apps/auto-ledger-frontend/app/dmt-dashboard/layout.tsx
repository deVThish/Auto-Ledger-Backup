"use client";

import React from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  UserPlus,
  LogOut,
  FileWarning,
} from "lucide-react";

export default function DMTLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();

  const handleLogout = () => {
    localStorage.clear();
    router.push("/login");
  };

  const getHeaderDetails = () => {
    if (pathname.includes("/add-driver"))
      return {
        title: "Issue New License",
        icon: (
          <UserPlus className="mr-3 text-cyan-400 drop-shadow-[0_0_8px_rgba(34,211,238,0.8)]" />
        ),
      };
    if (pathname.includes("/drivers"))
      return {
        title: "Driver Directory",
        icon: (
          <Users className="mr-3 text-cyan-400 drop-shadow-[0_0_8px_rgba(34,211,238,0.8)]" />
        ),
      };
    if (pathname.includes("/fines"))
      return {
        title: "Police Traffic Fines Database",
        icon: (
          <FileWarning className="mr-3 text-cyan-400 drop-shadow-[0_0_8px_rgba(34,211,238,0.8)]" />
        ),
      };
    return {
      title: "DMT Admin Dashboard",
      icon: (
        <LayoutDashboard className="mr-3 text-cyan-400 drop-shadow-[0_0_8px_rgba(34,211,238,0.8)]" />
      ),
    };
  };

  const header = getHeaderDetails();

  return (
    <div className="flex h-screen bg-[#030508] text-slate-200 overflow-hidden font-sans relative">
      <div className="absolute inset-0 z-0 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-[#110c24] via-[#050810] to-[#030407]"></div>

      <aside className="w-72 bg-[#0a0f16]/50 backdrop-blur-3xl border-r border-white/5 flex flex-col p-6 m-4 rounded-[2.5rem] shadow-[0_0_40px_rgba(0,229,255,0.03)] z-10">
        <div className="mb-8 text-center flex flex-col items-center">
          <div className="w-24 h-24 mb-4 flex items-center justify-center rounded-full bg-black/40 backdrop-blur-md p-1 shadow-[0_0_20px_rgba(34,211,238,0.1)] border border-white/10">
            <img
              src="/dmt_logo.png"
              alt="DMT Logo"
              className="w-full h-full object-contain rounded-full"
            />
          </div>
          <h1 className="text-xl font-black tracking-widest text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 to-purple-400 mt-2">
            DMT SYSTEM
          </h1>
          <p className="text-[10px] text-cyan-500/70 tracking-[0.3em] uppercase mt-1 font-bold">
            Administration
          </p>
        </div>

        <nav className="flex-1 space-y-2 mt-4">
          <SidebarBtn
            to="/dmt-dashboard"
            icon={<LayoutDashboard size={20} />}
            label="Overview"
            currentPath={pathname}
          />
          <SidebarBtn
            to="/dmt-dashboard/add-driver"
            icon={<UserPlus size={20} />}
            label="Issue License"
            currentPath={pathname}
          />
          <SidebarBtn
            to="/dmt-dashboard/drivers"
            icon={<Users size={20} />}
            label="Driver Directory"
            currentPath={pathname}
          />
          <SidebarBtn
            to="/dmt-dashboard/fines"
            icon={<FileWarning size={20} />}
            label="Traffic Fines"
            currentPath={pathname}
          />
        </nav>

        <button
          onClick={handleLogout}
          className="flex items-center justify-center px-5 py-3 mt-auto bg-gradient-to-r from-rose-500/10 to-transparent text-rose-400 hover:from-rose-500/20 rounded-2xl transition-all border border-rose-500/10 hover:border-rose-500/30 group"
        >
          <LogOut
            size={18}
            className="mr-3 group-hover:-translate-x-1 transition-transform"
          />
          <span className="font-bold text-sm tracking-wide">Logout</span>
        </button>
      </aside>

      <main className="flex-1 flex flex-col p-8 overflow-y-auto z-10 custom-scrollbar relative">
        <header className="flex justify-between items-center mb-8 bg-[#0a0f16]/40 backdrop-blur-2xl p-4 px-8 rounded-[2rem] border border-white/5 shadow-lg shadow-black/50">
          <div>
            <h2 className="text-2xl font-bold text-white capitalize flex items-center tracking-wide">
              {header.icon}
              {header.title}
            </h2>
          </div>
          <div className="flex items-center space-x-4">
            <div className="bg-[#050810] p-1.5 pr-5 rounded-full border border-cyan-500/20 flex items-center space-x-3 shadow-[0_0_15px_rgba(34,211,238,0.05)]">
              <div className="w-9 h-9 rounded-full bg-gradient-to-br from-cyan-400 to-purple-600 flex items-center justify-center font-black text-[#030407] text-sm tracking-tighter">
                DA
              </div>
              <span className="text-sm font-bold text-cyan-100/80">
                DMT Admin
              </span>
            </div>
          </div>
        </header>
        {children}
      </main>

      <style
        dangerouslySetInnerHTML={{
          __html: `
        .custom-scrollbar::-webkit-scrollbar { width: 6px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: rgba(5, 8, 16, 0.5); border-radius: 10px; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: linear-gradient(to bottom, rgba(34,211,238,0.3), rgba(147,51,234,0.3)); border-radius: 10px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: linear-gradient(to bottom, rgba(34,211,238,0.6), rgba(147,51,234,0.6)); }
      `,
        }}
      />
    </div>
  );
}

function SidebarBtn({
  to,
  icon,
  label,
  currentPath,
}: {
  to: string;
  icon: any;
  label: string;
  currentPath: string;
}) {
  const isActive = currentPath === to;
  return (
    <Link
      href={to}
      className={`flex items-center w-full px-5 py-3.5 rounded-2xl transition-all duration-500 group text-sm relative overflow-hidden ${isActive ? "bg-gradient-to-r from-cyan-500/10 to-purple-500/5 border border-white/10 shadow-[inset_0_1px_0_rgba(255,255,255,0.1)] text-cyan-50" : "hover:bg-white/[0.02] text-slate-400 hover:text-cyan-300 border border-transparent"}`}
    >
      {isActive && (
        <div className="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-cyan-400 to-purple-500 rounded-r-full shadow-[0_0_10px_rgba(34,211,238,1)]"></div>
      )}
      <span
        className={`mr-4 transition-transform duration-500 ${isActive ? "text-cyan-400 scale-110 drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]" : "group-hover:scale-110"}`}
      >
        {icon}
      </span>
      <span className="font-bold tracking-wider">{label}</span>
    </Link>
  );
}
