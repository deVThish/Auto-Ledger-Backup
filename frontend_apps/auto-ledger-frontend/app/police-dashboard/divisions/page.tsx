"use client";

import React, { useState, useEffect } from "react";
import { Map, PlusCircle, AlertCircle, CheckCircle2, X } from "lucide-react";
import { api } from "@/lib/api";

interface DivisionalHeadInfo {
  divisional_Head_Id: string;
  name: string;
}

interface Division {
  division_Id: string;
  division_Name: string;
  divisionalHeads?: DivisionalHeadInfo[];
}

interface ApiError {
  response?: {
    data?: {
      message?: string;
    };
  };
}

export default function ManageDivisions() {
  const [divisions, setDivisions] = useState<Division[]>([]);
  const [divisionForm, setDivisionForm] = useState({
    divisionId: "DIV-",
    divisionName: "",
  });
  const [toast, setToast] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  const showToast = (type: "success" | "error", message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const loadDivisions = async () => {
    const res = await api.get<Division[]>("/officers/divisions");
    setDivisions(res.data);
  };

  useEffect(() => {
    async function fetchDivisions() {
      try {
        await loadDivisions();
      } catch (err) {
        console.error(err);
      }
    }
    void fetchDivisions();
  }, []);

  const handleIdChange = (val: string) => {
    if (!val.startsWith("DIV-")) {
      setDivisionForm({ ...divisionForm, divisionId: "DIV-" });
    } else {
      setDivisionForm({ ...divisionForm, divisionId: val.toUpperCase() });
    }
  };

  const handleDivisionSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const idPattern = /^DIV-\d{3,}$/;
    if (!idPattern.test(divisionForm.divisionId)) {
      showToast(
        "error",
        'Invalid ID format! Must contain "DIV-" followed by at least 3 digits.',
      );
      return;
    }

    try {
      await api.post("/officers/division", {
        divisionId: divisionForm.divisionId,
        divisionName: divisionForm.divisionName,
      });
      showToast("success", "New Police Division created successfully!");
      setDivisionForm({ divisionId: "DIV-", divisionName: "" });
      await loadDivisions();
    } catch (err: unknown) {
      const error = err as ApiError;
      showToast(
        "error",
        error.response?.data?.message || "Error creating division",
      );
    }
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-500 relative">
      {toast && (
        <div
          className={`fixed top-6 right-6 z-50 flex items-center p-4 rounded-2xl shadow-2xl border backdrop-blur-xl ${toast.type === "error" ? "bg-red-950/80 border-red-500/50 text-red-200" : "bg-emerald-950/80 border-emerald-500/50 text-emerald-200"}`}
        >
          {toast.type === "error" ? (
            <AlertCircle className="text-red-400 mr-3" size={20} />
          ) : (
            <CheckCircle2 className="text-emerald-400 mr-3" size={20} />
          )}
          <span className="text-xs font-bold tracking-wide">
            {toast.message}
          </span>
          <button
            onClick={() => setToast(null)}
            className="ml-4 p-1 text-slate-400 hover:text-white"
          >
            <X size={14} />
          </button>
        </div>
      )}

      <form
        onSubmit={handleDivisionSubmit}
        className="bg-[#0b1c3b]/60 p-8 rounded-3xl border border-[#1a2f5c] shadow-xl backdrop-blur-sm"
      >
        <h3 className="text-lg font-bold text-amber-500 mb-6 flex items-center">
          <Map className="mr-2" size={18} /> Register New Police Division
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">
              Division ID *
            </label>
            <input
              required
              value={divisionForm.divisionId}
              onChange={(e) => handleIdChange(e.target.value)}
              type="text"
              placeholder="DIV-001"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white font-mono"
            />
          </div>
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">
              Division Name *
            </label>
            <input
              required
              value={divisionForm.divisionName}
              onChange={(e) =>
                setDivisionForm({
                  ...divisionForm,
                  divisionName: e.target.value,
                })
              }
              type="text"
              placeholder="e.g. Galle Division"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white"
            />
          </div>
        </div>
        <div className="flex justify-end border-t border-[#1a2f5c] pt-6">
          <button
            type="submit"
            className="bg-amber-600 hover:bg-amber-500 text-white px-8 py-3 rounded-xl font-bold flex items-center shadow-lg shadow-amber-900/40"
          >
            <PlusCircle size={18} className="mr-2" /> Register Division
          </button>
        </div>
      </form>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050d1a] text-slate-400 text-xs uppercase tracking-widest">
            <tr>
              <th className="p-4">Division ID</th>
              <th className="p-4">Division Name</th>
              <th className="p-4">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#1a2f5c]">
            {divisions.map((division) => (
              <tr
                key={division.division_Id}
                className="hover:bg-[#132752]/50 transition-all"
              >
                <td className="p-4 font-mono font-bold text-amber-500">
                  {division.division_Id}
                </td>
                <td className="p-4 font-bold text-white">
                  {division.division_Name}
                </td>
                <td className="p-4">
                  {division.divisionalHeads &&
                  division.divisionalHeads.length > 0 ? (
                    <span className="text-emerald-400 text-xs bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 rounded">
                      Active Head: {division.divisionalHeads[0].name}
                    </span>
                  ) : (
                    <span className="text-amber-400 text-xs bg-amber-500/10 border border-amber-500/20 px-2 py-0.5 rounded">
                      Vacant
                    </span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
