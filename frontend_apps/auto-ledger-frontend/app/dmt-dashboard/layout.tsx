"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  UserPlus,
  LogOut,
  FileWarning,
  Ban,
  Menu, // <-- Hamburger Icon
} from "lucide-react";

export default function DMTLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [isLoading, setIsLoading] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(false); // <-- Sidebar Toggle State

  useEffect(() => {
    const checkAuth = setTimeout(() => {
      const role = localStorage.getItem("userRole");
      if (role !== "DMT_ADMIN") {
        router.push("/login");
      } else {
        setIsLoading(false);
      }
    }, 0);

    return () => clearTimeout(checkAuth);
  }, [router]);

  // Close sidebar on window resize to desktop
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth >= 768) {
        setSidebarOpen(false);
      }
    };
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

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
    if (pathname.includes("/revoked"))
      return {
        title: "Actioned Licenses Registry",
        icon: (
          <Ban className="mr-3 text-red-500 drop-shadow-[0_0_8px_rgba(239,68,68,0.8)]" />
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

  if (isLoading) {
    return null;
  }

  return (
    <div className="flex h-screen bg-[#030508] text-slate-200 overflow-hidden font-sans relative">
      <div className="absolute inset-0 z-0 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-[#110c24] via-[#050810] to-[#030407]"></div>

      {/* Mobile Overlay */}
      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 bg-black/60 z-40 md:hidden"
        ></div>
      )}

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 w-72 bg-[#0a0f16]/90 backdrop-blur-3xl border-r border-white/5 flex flex-col p-6 transition-transform duration-300 ease-in-out transform ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        } md:relative md:translate-x-0 md:flex`}
      >
        <div className="mb-8 text-center flex flex-col items-center">
          <div className="relative w-24 h-24 mb-4 flex items-center justify-center rounded-full bg-black/40 backdrop-blur-md p-1 shadow-[0_0_20px_rgba(34,211,238,0.1)] border border-white/10 overflow-hidden">
            <Image
              src="/dmt_logo.png"
              alt="DMT Logo"
              width={96}
              height={96}
              className="w-full h-full object-contain rounded-full"
              priority
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
            to="/dmt-dashboard/revoked"
            icon={<Ban size={20} />}
            label="Revoked Licenses"
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

      <main className="flex-1 flex flex-col p-4 md:p-8 overflow-y-auto z-10 custom-scrollbar relative">
        <header className="flex justify-between items-center mb-8 bg-[#0a0f16]/40 backdrop-blur-2xl p-3 md:p-4 px-4 md:px-8 rounded-[2rem] border border-white/5 shadow-lg shadow-black/50">
          <div className="flex items-center">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="md:hidden text-cyan-400 mr-3 p-1 hover:bg-white/10 rounded-lg transition-colors"
            >
              <Menu size={24} />
            </button>
            <h2 className="text-xl md:text-2xl font-bold text-white capitalize flex items-center tracking-wide">
              {header.icon}
              <span className="hidden sm:inline">{header.title}</span>
              <span className="sm:hidden">
                {header.title.split(" ").slice(0, 2).join(" ")}
              </span>
            </h2>
          </div>
          <div className="flex items-center space-x-4">
            <div className="bg-[#050810] p-1.5 pr-5 rounded-full border border-cyan-500/20 flex items-center space-x-3 shadow-[0_0_15px_rgba(34,211,238,0.05)]">
              <div className="w-9 h-9 rounded-full bg-gradient-to-br from-cyan-400 to-purple-600 flex items-center justify-center font-black text-[#030407] text-sm tracking-tighter">
                DA
              </div>
              <span className="text-sm font-bold text-cyan-100/80 hidden sm:inline">
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
  icon: React.ReactNode;
  label: string;
  currentPath: string;
}) {
  const isActive = currentPath === to;
  return (
    <Link
      href={to}
      className={`flex items-center w-full px-5 py-3.5 rounded-2xl transition-all duration-500 group text-sm relative overflow-hidden ${
        isActive
          ? "bg-gradient-to-r from-cyan-500/10 to-purple-500/5 border border-white/10 shadow-[inset_0_1px_0_rgba(255,255,255,0.1)] text-cyan-50"
          : "hover:bg-white/[0.02] text-slate-400 hover:text-cyan-300 border border-transparent"
      }`}
    >
      {isActive && (
        <div className="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-cyan-400 to-purple-500 rounded-r-full shadow-[0_0_10px_rgba(34,211,238,1)]"></div>
      )}
      <span
        className={`mr-4 transition-transform duration-500 ${
          isActive
            ? "text-cyan-400 scale-110 drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]"
            : "group-hover:scale-110"
        }`}
      >
        {icon}
      </span>
      <span className="font-bold tracking-wider">{label}</span>
    </Link>
  );
}