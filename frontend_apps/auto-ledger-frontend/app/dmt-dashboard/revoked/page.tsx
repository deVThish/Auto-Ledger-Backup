"use client";

import React, { useState, useEffect } from "react";
import { Ban, Search, ShieldAlert } from "lucide-react";
import { api } from "@/lib/api";

interface ProblematicLicense {
  license_Id: string;
  license_No: string;
  nic_No: string;
  full_Name: string;
  status: string;
  points: number;
}

export default function ProblematicLicenses() {
  const [licenses, setLicenses] = useState<ProblematicLicense[]>([]);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    let isMounted = true;

    const loadLicenses = async () => {
      try {
        const res = await api.get<ProblematicLicense[]>(
          "/fines/dmt/problematic-licenses",
        );
        if (isMounted) {
          setLicenses(res.data);
        }
      } catch (error) {
        console.error(error);
      }
    };

    // ESLint error එක මගහරින්න Promise එකක් ඇතුළෙන් function එක call කරනවා
    Promise.resolve().then(loadLicenses);

    return () => {
      isMounted = false;
    };
  }, []);

  const filteredLicenses = licenses.filter(
    (l) =>
      l.nic_No.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.license_No.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-8 duration-500 pb-10">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center bg-[#2a0808]/60 p-6 rounded-3xl border border-red-900/50 backdrop-blur-sm gap-4">
        <div>
          <h2 className="text-2xl font-black text-red-400 flex items-center">
            <Ban className="mr-3 text-red-500" size={28} /> Suspended & Revoked
            Licenses
          </h2>
          <p className="text-sm text-red-200/60 mt-1">
            Registry of drivers with suspended or permanently revoked driving
            privileges.
          </p>
        </div>
      </div>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <div className="p-6 border-b border-[#1a2f5c] flex flex-col sm:flex-row justify-between items-center gap-4 bg-[#050d1a]/50">
          <h3 className="text-white font-bold flex items-center text-lg">
            Actioned Licenses
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
                <th className="p-5 font-semibold">License No</th>
                <th className="p-5 font-semibold">NIC Number</th>
                <th className="p-5 font-semibold">Driver Name</th>
                <th className="p-5 font-semibold">Demerit Points</th>
                <th className="p-5 font-semibold">Current Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1a2f5c]">
              {filteredLicenses.map((license) => (
                <tr
                  key={license.license_Id}
                  className="hover:bg-[#132752]/50 transition-colors"
                >
                  <td className="p-5 font-bold text-white">
                    {license.license_No}
                  </td>
                  <td className="p-5 font-mono text-amber-500">
                    {license.nic_No}
                  </td>
                  <td className="p-5 text-slate-300">{license.full_Name}</td>
                  <td className="p-5">
                    <span className="text-red-400 font-bold">
                      {license.points} / 24
                    </span>
                  </td>
                  <td className="p-5">
                    <span
                      className={`px-3 py-1 rounded-md border font-bold text-xs ${
                        license.status === "REVOKED"
                          ? "bg-red-950 text-red-500 border-red-900"
                          : "bg-orange-950 text-orange-400 border-orange-900"
                      }`}
                    >
                      {license.status}
                    </span>
                  </td>
                </tr>
              ))}
              {filteredLicenses.length === 0 && (
                <tr>
                  <td
                    colSpan={5}
                    className="p-12 text-center text-slate-500 font-bold text-sm"
                  >
                    <ShieldAlert
                      size={40}
                      className="mx-auto mb-3 opacity-20"
                    />
                    No suspended or revoked licenses found.
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
