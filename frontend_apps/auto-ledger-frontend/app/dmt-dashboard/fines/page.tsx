"use client";

import React, { useState } from 'react';
import { Search, Eye, X, FileWarning, ShieldAlert, Gavel, Calendar } from 'lucide-react';

export default function DMTStandaloneFinesPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedLicenseFines, setSelectedLicenseFines] = useState<any | null>(null);

  const [licensesWithFines] = useState([
    {
      licenseNo: 'B5544123', fullName: 'Nimal Perera', nicNo: '851234567V', totalActiveFines: 2, totalDemeritPoints: 14,
      finesList: [
        { id: 101, code: 'SPD-01', description: 'Speeding over 70kmph', points: 4, amount: 3000, date: '2026-05-14', isCourtCase: false },
        { id: 102, code: 'DRK-02', description: 'Driving under influence of liquor', points: 10, amount: 25000, date: '2026-06-01', isCourtCase: true }
      ]
    },
    {
      licenseNo: 'B5544456', fullName: 'Kasun Silva', nicNo: '921234567V', totalActiveFines: 1, totalDemeritPoints: 6,
      finesList: [
        { id: 103, code: 'LGN-03', description: 'Driving without a valid insurance covering', points: 6, amount: 10000, date: '2026-06-12', isCourtCase: false }
      ]
    }
  ]);

  const filteredRecords = licensesWithFines.filter(l => 
    l.nicNo.toLowerCase().includes(searchQuery.toLowerCase()) || 
    l.licenseNo.toLowerCase().includes(searchQuery.toLowerCase()) ||
    l.fullName.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-700 pb-10">
      
      <div className="bg-[#0a0f16]/60 border border-white/5 rounded-[2.5rem] p-6 backdrop-blur-2xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.8)] flex flex-col md:flex-row justify-between items-center gap-4 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-purple-500/10 rounded-full blur-[80px] pointer-events-none"></div>
        <div className="relative z-10">
          <h3 className="text-xl font-bold text-white flex items-center tracking-wide"><FileWarning className="mr-3 text-cyan-400 drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]" size={24} /> Active Offenses Database</h3>
          <p className="text-sm text-slate-400 mt-1">DMT Read-Only Lookup for licenses with active traffic tickets.</p>
        </div>
        <div className="relative w-full md:w-96 z-10">
          <Search className="absolute left-4 top-3 text-cyan-500/50" size={18} />
          <input type="text" placeholder="Search by NIC or License No..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="w-full bg-[#030508]/80 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-sm focus:border-cyan-400/50 outline-none text-white placeholder-slate-500 focus:ring-1 focus:ring-cyan-400/20 transition-all"/>
        </div>
      </div>

      <div className="bg-[#0a0f16]/60 border border-white/5 rounded-[2.5rem] overflow-hidden backdrop-blur-2xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050810]/50 text-cyan-500/50 text-[11px] uppercase tracking-[0.2em] border-b border-white/5">
            <tr>
              <th className="p-5 font-black">License No</th>
              <th className="p-5 font-black">Driver Name</th>
              <th className="p-5 font-black">NIC Number</th>
              <th className="p-5 text-center font-black">Active Fines</th>
              <th className="p-5 text-center font-black">Demerit Points</th>
              <th className="p-5 text-center font-black">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {filteredRecords.length > 0 ? filteredRecords.map(record => (
              <tr key={record.licenseNo} className="hover:bg-white/[0.02] transition-all duration-300">
                <td className="p-5 font-mono font-bold text-cyan-400/80 tracking-wider">{record.licenseNo}</td>
                <td className="p-5 font-bold text-slate-200">{record.fullName}</td>
                <td className="p-5 text-slate-400 tracking-wide">{record.nicNo}</td>
                <td className="p-5 text-center">
                  <span className="bg-purple-500/10 text-purple-400 px-3 py-1.5 rounded-xl text-[10px] font-black border border-purple-500/20 tracking-wider shadow-[0_0_10px_rgba(168,85,247,0.1)]">
                    {record.totalActiveFines} Tickets
                  </span>
                </td>
                <td className="p-5 text-center">
                  <span className="bg-rose-500/10 text-rose-400 px-3 py-1.5 rounded-xl text-[10px] font-black border border-rose-500/20 tracking-wider shadow-[0_0_10px_rgba(244,63,94,0.1)]">
                    {record.totalDemeritPoints} Pts
                  </span>
                </td>
                <td className="p-5 text-center">
                  <button onClick={() => setSelectedLicenseFines(record)} className="bg-cyan-950/30 hover:bg-cyan-900/50 text-cyan-400 hover:text-cyan-200 border border-cyan-500/20 hover:border-cyan-400/50 px-4 py-2.5 rounded-xl font-bold transition-all text-xs flex items-center mx-auto shadow-[0_0_10px_rgba(34,211,238,0.05)] hover:shadow-[0_0_15px_rgba(34,211,238,0.2)]">
                    <Eye size={14} className="mr-1.5" /> View Logs
                  </button>
                </td>
              </tr>
            )) : (
              <tr><td colSpan={6} className="p-8 text-center text-slate-500 tracking-widest uppercase text-xs font-bold">No active fine records found.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {selectedLicenseFines && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#030407]/90 backdrop-blur-md animate-in fade-in duration-300">
          <div className="bg-[#0a0f16]/95 border border-cyan-500/20 rounded-[2.5rem] w-full max-w-3xl max-h-[85vh] overflow-y-auto shadow-[0_0_50px_rgba(34,211,238,0.1)] custom-scrollbar relative">
            
            <div className="sticky top-0 bg-[#050810]/80 backdrop-blur-xl p-6 border-b border-white/5 flex justify-between items-center z-20">
              <div className="flex items-center space-x-3">
                <ShieldAlert className="text-rose-500 animate-pulse drop-shadow-[0_0_5px_rgba(244,63,94,0.8)]" size={24} />
                <h3 className="text-xl font-black text-white tracking-wide">Fines Ledger: <span className="text-cyan-100">{selectedLicenseFines.fullName}</span> <span className="text-cyan-500/50 font-mono text-lg tracking-widest ml-2">({selectedLicenseFines.licenseNo})</span></h3>
              </div>
              <button onClick={() => setSelectedLicenseFines(null)} className="p-2 text-slate-400 hover:text-white bg-white/5 rounded-full hover:bg-rose-600/20 hover:text-rose-400 transition-all border border-transparent hover:border-rose-500/30"><X size={20}/></button>
            </div>

            <div className="p-8 space-y-6 relative z-10">
              <div className="grid grid-cols-2 gap-4 bg-gradient-to-r from-purple-950/30 to-rose-950/30 border border-purple-500/20 p-5 rounded-[1.5rem] text-[11px] font-bold text-slate-400 uppercase tracking-widest">
                <p>NIC: <span className="text-white ml-2 tracking-wider">{selectedLicenseFines.nicNo}</span></p>
                <p>Total Demerit Accounted: <span className="text-rose-400 ml-2 font-mono text-sm drop-shadow-[0_0_2px_rgba(244,63,94,0.5)]">{selectedLicenseFines.totalDemeritPoints} / 24</span></p>
              </div>

              <div className="space-y-4">
                {selectedLicenseFines.finesList.map((fine: any) => (
                  <div key={fine.id} className="bg-[#050810] border border-white/5 p-6 rounded-[1.5rem] space-y-4 relative overflow-hidden group hover:border-white/10 transition-colors">
                    <div className="absolute top-0 left-0 w-1.5 h-full bg-gradient-to-b from-rose-500 to-purple-600 shadow-[0_0_10px_rgba(244,63,94,0.8)]"></div>
                    <div className="flex justify-between items-start pl-2">
                      <div>
                        <span className="font-mono text-[10px] font-black text-rose-400 bg-rose-950/30 px-2.5 py-1 rounded-md border border-rose-500/20 tracking-widest shadow-[0_0_5px_rgba(244,63,94,0.1)]">{fine.code}</span>
                        <h4 className="text-cyan-50 font-bold text-base mt-3 tracking-wide">{fine.description}</h4>
                      </div>
                      <div className="text-right">
                        <p className="text-white font-black text-xl font-mono tracking-wider drop-shadow-md">LKR {fine.amount.toLocaleString()}.00</p>
                        <p className="text-[10px] text-cyan-500/50 font-bold uppercase mt-1.5 flex items-center justify-end tracking-widest"><Calendar size={12} className="mr-1.5 text-purple-400/70"/> {fine.date}</p>
                      </div>
                    </div>
                    <div className="flex justify-between items-center pt-4 border-t border-white/5 text-xs pl-2">
                      <span className="text-slate-400 font-medium tracking-wide">Demerit Deduction: <span className="text-rose-500 font-black font-mono ml-1 drop-shadow-[0_0_2px_rgba(244,63,94,0.5)]">+{fine.points} Points</span></span>
                      {fine.isCourtCase ? (
                        <span className="text-rose-300 font-black uppercase tracking-[0.15em] text-[9px] bg-rose-950/40 border border-rose-500/30 px-3 py-1.5 rounded-lg flex items-center shadow-[0_0_10px_rgba(244,63,94,0.15)]"><Gavel size={14} className="mr-1.5"/> Court Appearance Mandatory</span>
                      ) : (
                        <span className="text-cyan-500/50 font-bold tracking-widest uppercase text-[10px]">Standard Penalty Fine</span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

          </div>
        </div>
      )}
    </div>
  );
}