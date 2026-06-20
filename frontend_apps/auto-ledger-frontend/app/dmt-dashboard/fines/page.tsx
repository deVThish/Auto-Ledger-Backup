"use client";

import React, { useState, useEffect } from "react";
// AlertCircle එක පාවිච්චි වෙන්නේ නැති නිසා අයින් කළා
import { FileText, Search, ShieldAlert } from "lucide-react";
import { api } from "@/lib/api";

interface DMTFine {
  fine_Id: string;
  issue_At: string;
  status: string;
  license: {
    license_No: string;
    nic_No: string;
    full_Name: string;
  };
  offenses: {
    offenceCategory: {
      code: string;
      name: string;
      amount: number;
    };
  }[];
}

export default function DMTFinesOverview() {
  const [fines, setFines] = useState<DMTFine[]>([]);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    let isMounted = true;

    const loadFines = async () => {
      try {
        const res = await api.get<DMTFine[]>("/fines/dmt/all-fines");
        if (isMounted) {
          setFines(res.data);
        }
      } catch (error) {
        console.error(error);
      }
    };

    // ESLint error එක මගහරින්න Micro-task එකක් විදිහට call කරනවා
    Promise.resolve().then(loadFines);

    return () => {
      isMounted = false;
    };
  }, []);

  const filteredFines = fines.filter(
    (f) =>
      f.license.nic_No.toLowerCase().includes(searchTerm.toLowerCase()) ||
      f.license.license_No.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-8 duration-500 pb-10">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center bg-[#0b1c3b]/40 p-6 rounded-3xl border border-[#1a2f5c] backdrop-blur-sm gap-4">
        <div>
          <h2 className="text-2xl font-black text-white flex items-center">
            <FileText className="mr-3 text-amber-500" size={28} /> Issued Fines
            Overview
          </h2>
          <p className="text-sm text-slate-400 mt-1">
            Search and view traffic fine records by NIC or License Number.
          </p>
        </div>
      </div>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <div className="p-6 border-b border-[#1a2f5c] flex flex-col sm:flex-row justify-between items-center gap-4 bg-[#050d1a]/50">
          <h3 className="text-white font-bold flex items-center text-lg">
            Fine Records
          </h3>
          <div className="relative w-full sm:w-80">
            <Search
              className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
              size={16}
            />
            <input
              type="text"
              placeholder="Search by NIC or License No..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-[#030508] border border-[#1a2f5c] rounded-full pl-10 pr-4 py-2.5 text-sm focus:border-amber-500 outline-none text-white transition-colors"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-[#030508] text-slate-400 text-xs uppercase tracking-widest">
              <tr>
                <th className="p-5 font-semibold">License Info</th>
                <th className="p-5 font-semibold">NIC</th>
                <th className="p-5 font-semibold">Offenses</th>
                <th className="p-5 font-semibold">Total Amount</th>
                <th className="p-5 font-semibold">Status</th>
                <th className="p-5 font-semibold">Issued Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1a2f5c]">
              {filteredFines.map((fine) => {
                const totalAmount = fine.offenses.reduce(
                  (sum, o) => sum + o.offenceCategory.amount,
                  0,
                );
                return (
                  <tr
                    key={fine.fine_Id}
                    className="hover:bg-[#132752]/50 transition-colors"
                  >
                    <td className="p-5">
                      <p className="font-bold text-white">
                        {fine.license.license_No}
                      </p>
                      <p className="text-xs text-slate-400">
                        {fine.license.full_Name}
                      </p>
                    </td>
                    <td className="p-5 font-mono text-amber-500">
                      {fine.license.nic_No}
                    </td>
                    <td className="p-5">
                      <div className="flex flex-wrap gap-1">
                        {fine.offenses.map((o, idx) => (
                          <span
                            key={idx}
                            className="bg-blue-500/10 text-blue-400 px-2 py-1 rounded text-xs border border-blue-500/20"
                            title={o.offenceCategory.name}
                          >
                            {o.offenceCategory.code}
                          </span>
                        ))}
                      </div>
                    </td>
                    <td className="p-5 font-bold text-slate-200">
                      LKR {totalAmount.toLocaleString()}
                    </td>
                    <td className="p-5">
                      <span
                        className={`px-2.5 py-1 rounded-md border font-bold text-xs ${
                          fine.status === "PAID"
                            ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
                            : fine.status === "OVERDUE"
                              ? "bg-red-500/10 text-red-400 border-red-500/20"
                              : "bg-amber-500/10 text-amber-400 border-amber-500/20"
                        }`}
                      >
                        {fine.status}
                      </span>
                    </td>
                    <td className="p-5 text-slate-300">
                      {new Date(fine.issue_At).toLocaleDateString()}
                    </td>
                  </tr>
                );
              })}
              {filteredFines.length === 0 && (
                <tr>
                  <td
                    colSpan={6}
                    className="p-12 text-center text-slate-500 font-bold text-sm"
                  >
                    <ShieldAlert
                      size={40}
                      className="mx-auto mb-3 opacity-20"
                    />
                    No fines found matching your search.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
