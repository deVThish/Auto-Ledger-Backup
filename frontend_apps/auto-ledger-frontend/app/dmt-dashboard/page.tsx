"use client";

import React from 'react';
import Link from 'next/link';
import { Users, CheckCircle, AlertTriangle, ArrowRight, CreditCard } from 'lucide-react';

export default function DMTDashboard() {
  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Changed Colors to Rare Cyber/Neon variants */}
        <StatCard title="Total Registered" value="12,450" icon={<Users />} color="cyan" />
        <StatCard title="Active Licenses" value="11,890" icon={<CheckCircle />} color="purple" />
        <StatCard title="Suspended" value="560" icon={<AlertTriangle />} color="pink" />
      </div>

      <div className="bg-[#0a0f16]/60 border border-white/5 rounded-[2.5rem] p-8 backdrop-blur-2xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.8)] mt-8 relative overflow-hidden">
        {/* Subtle glow orb in the background of the table container */}
        <div className="absolute -top-24 -right-24 w-64 h-64 bg-cyan-500/10 rounded-full blur-[80px] pointer-events-none"></div>

        <div className="flex justify-between items-center mb-8 border-b border-white/5 pb-4 relative z-10">
          <h3 className="text-xl font-bold text-white flex items-center tracking-wide">
            <CreditCard className="mr-3 text-cyan-400 drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]" size={20}/> Recently Issued Licenses
          </h3>
          <Link href="/dmt-dashboard/drivers" className="flex items-center text-sm font-bold text-cyan-300 hover:text-cyan-100 bg-cyan-950/30 border border-cyan-500/20 hover:border-cyan-400/50 hover:bg-cyan-900/40 hover:shadow-[0_0_15px_rgba(34,211,238,0.2)] px-5 py-2.5 rounded-xl transition-all duration-300">
            View Full Directory <ArrowRight size={16} className="ml-2"/>
          </Link>
        </div>

        <div className="overflow-x-auto relative z-10">
          <table className="w-full text-left">
            <thead className="text-cyan-500/50 text-[11px] uppercase tracking-[0.2em] border-b border-white/5">
              <tr>
                <th className="pb-4 px-4 font-black">Driver Name</th>
                <th className="pb-4 px-4 font-black">NIC Number</th>
                <th className="pb-4 px-4 font-black">License No</th>
                <th className="pb-4 px-4 font-black">Initial Issue Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5 text-sm">
              <tr className="hover:bg-white/[0.02] transition-colors duration-300 group">
                <td className="py-5 px-4 font-bold text-slate-200 flex items-center group-hover:text-white transition-colors">
                  <img src="https://i.pravatar.cc/150?u=nimal" className="w-9 h-9 rounded-full mr-4 border border-cyan-500/30 shadow-[0_0_10px_rgba(34,211,238,0.1)]" alt="pic"/> 
                  Nimal Perera
                </td>
                <td className="py-5 px-4 text-slate-400 tracking-wide">851234567V</td>
                <td className="py-5 px-4 font-mono text-cyan-400/80 font-bold tracking-wider group-hover:text-cyan-300 group-hover:drop-shadow-[0_0_5px_rgba(34,211,238,0.5)] transition-all">B5544123</td>
                <td className="py-5 px-4 text-slate-500 font-medium">2024-01-10</td>
              </tr>
              <tr className="hover:bg-white/[0.02] transition-colors duration-300 group">
                <td className="py-5 px-4 font-bold text-slate-200 flex items-center group-hover:text-white transition-colors">
                  <img src="https://i.pravatar.cc/150?u=kasun" className="w-9 h-9 rounded-full mr-4 border border-cyan-500/30 shadow-[0_0_10px_rgba(34,211,238,0.1)]" alt="pic"/> 
                  Kasun Silva
                </td>
                <td className="py-5 px-4 text-slate-400 tracking-wide">921234567V</td>
                <td className="py-5 px-4 font-mono text-cyan-400/80 font-bold tracking-wider group-hover:text-cyan-300 group-hover:drop-shadow-[0_0_5px_rgba(34,211,238,0.5)] transition-all">B5544456</td>
                <td className="py-5 px-4 text-slate-500 font-medium">2022-05-11</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

// Ultra-Modern Stat Card Design
function StatCard({ title, value, icon, color }: any) {
  const colorMap: any = {
    cyan: 'from-cyan-500/10 to-transparent border-cyan-500/20 text-cyan-400 bg-cyan-950/30 shadow-[0_0_20px_rgba(34,211,238,0.05)] icon-cyan',
    purple: 'from-purple-500/10 to-transparent border-purple-500/20 text-purple-400 bg-purple-950/30 shadow-[0_0_20px_rgba(168,85,247,0.05)] icon-purple',
    pink: 'from-pink-500/10 to-transparent border-pink-500/20 text-pink-400 bg-pink-950/30 shadow-[0_0_20px_rgba(236,72,153,0.05)] icon-pink'
  };
  
  const iconColors: any = {
    cyan: 'bg-gradient-to-br from-cyan-400 to-blue-600 text-[#030407] shadow-[0_0_15px_rgba(34,211,238,0.4)]',
    purple: 'bg-gradient-to-br from-purple-400 to-fuchsia-600 text-[#030407] shadow-[0_0_15px_rgba(168,85,247,0.4)]',
    pink: 'bg-gradient-to-br from-pink-400 to-rose-600 text-[#030407] shadow-[0_0_15px_rgba(236,72,153,0.4)]'
  };

  const selectedTheme = colorMap[color].split(' ');

  return (
    <div className={`p-6 rounded-[2rem] bg-gradient-to-br ${selectedTheme[0]} ${selectedTheme[1]} border ${selectedTheme[2]} backdrop-blur-xl ${selectedTheme[4]} group hover:-translate-y-1 hover:shadow-lg transition-all duration-500 relative overflow-hidden`}>
      {/* Subtle shine effect on hover */}
      <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/5 to-transparent -translate-x-full group-hover:translate-x-full duration-1000 ease-in-out pointer-events-none"></div>
      
      <div className={`w-12 h-12 rounded-2xl flex items-center justify-center mb-5 ${iconColors[color]} transform group-hover:scale-110 transition-transform duration-500`}>
        {icon}
      </div>
      <p className="text-slate-400 text-[11px] font-bold uppercase tracking-[0.15em] mb-1">{title}</p>
      <p className="text-4xl font-black text-white tracking-tight drop-shadow-md">{value}</p>
    </div>
  );
}