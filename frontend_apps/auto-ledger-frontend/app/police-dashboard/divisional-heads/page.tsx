"use client";

import React, { useState, useEffect } from "react";
import {
  Users,
  PlusCircle,
  MapPin,
  AlertCircle,
  CheckCircle2,
  X,
  Lock,
  User,
  Info,
  Eye,
  EyeOff,
} from "lucide-react";
import { api } from "@/lib/api";

interface Division {
  division_Id: string;
  division_Name: string;
  divisionalHead?: Record<string, unknown> | null;
}

interface DivisionalHead {
  divisional_Head_Id: string;
  name: string;
  username: string;
  email: string;
  division?: {
    division_Name: string;
  };
}

interface ApiError {
  response?: {
    data?: {
      message?: string;
    };
  };
}

export default function ManageHeads() {
  const [divisions, setDivisions] = useState<Division[]>([]);
  const [heads, setHeads] = useState<DivisionalHead[]>([]);
  const [headForm, setHeadForm] = useState({
    name: "",
    username: "",
    divisionName: "",
    email: "",
    passwordStr: "",
  });
  const [toast, setToast] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  const showToast = (type: "success" | "error", message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const loadData = async () => {
    try {
      const [divRes, headRes] = await Promise.all([
        api.get<Division[]>("/officers/divisions"),
        api.get<DivisionalHead[]>("/officers/divisional-heads"),
      ]);
      setDivisions(divRes.data);
      setHeads(headRes.data);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    async function fetchData() {
      await loadData();
    }
    void fetchData();
  }, []);

  const handleHeadSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.post("/officers/head", {
        divisionName: headForm.divisionName,
        username: headForm.username,
        email: headForm.email,
        name: headForm.name,
        passwordStr: headForm.passwordStr,
      });

      showToast("success", "Divisional Head registered successfully!");
      setHeadForm({
        name: "",
        username: "",
        divisionName: "",
        email: "",
        passwordStr: "",
      });
      await loadData();
    } catch (err: unknown) {
      const error = err as ApiError;
      showToast(
        "error",
        error.response?.data?.message || "Error registering head",
      );
    }
  };

  const availableDivisions = divisions.filter((div) => !div.divisionalHead);
  const allOccupied = divisions.length > 0 && availableDivisions.length === 0;

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-500 relative">
      {toast && (
        <div
          className={`fixed top-6 right-6 z-50 flex items-center p-4 rounded-2xl shadow-2xl border backdrop-blur-xl ${toast.type === "error" ? "bg-red-950/80 border-red-500/50 text-red-200" : "bg-emerald-950/80 border-emerald-500/50 text-emerald-200"}`}
        >
          {toast.type === "error" ? (
            <AlertCircle
              className="text-red-400 mr-3 flex-shrink-0"
              size={20}
            />
          ) : (
            <CheckCircle2
              className="text-emerald-400 mr-3 flex-shrink-0"
              size={20}
            />
          )}
          <span className="text-xs font-bold tracking-wide leading-relaxed">
            {toast.message}
          </span>
          <button
            onClick={() => setToast(null)}
            className="ml-4 p-1 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"
          >
            <X size={14} />
          </button>
        </div>
      )}

      <form
        onSubmit={handleHeadSubmit}
        className="bg-[#0b1c3b]/60 p-8 rounded-3xl border border-[#1a2f5c] shadow-xl backdrop-blur-sm"
      >
        <h3 className="text-lg font-bold text-amber-500 mb-6 flex items-center">
          <Users className="mr-2" size={18} /> Register Divisional Head
        </h3>

        {allOccupied && (
          <div className="mb-8 w-full bg-[#132752]/40 border border-[#1a2f5c] rounded-2xl p-5 flex items-start shadow-inner">
            <div className="bg-blue-500/20 p-2 rounded-lg mr-4 flex-shrink-0 border border-blue-500/30">
              <Info size={20} className="text-blue-400" />
            </div>
            <div>
              <h4 className="text-blue-400 font-bold text-sm mb-1">
                Action Required: No Vacant Divisions
              </h4>
              <p className="text-slate-400 text-xs leading-relaxed">
                All currently active Police Divisions have already been assigned
                a Divisional Head. To register a new Divisional Head, you must
                first create a new Police Division in the system.
              </p>
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">
              Full Name *
            </label>
            <input
              required
              disabled={allOccupied}
              value={headForm.name}
              onChange={(e) =>
                setHeadForm({ ...headForm, name: e.target.value })
              }
              type="text"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white disabled:opacity-50 disabled:cursor-not-allowed"
            />
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase flex items-center">
              <MapPin size={12} className="mr-1 text-amber-500" /> Assign to
              Division *
            </label>
            <select
              required
              disabled={allOccupied}
              value={headForm.divisionName}
              onChange={(e) =>
                setHeadForm({ ...headForm, divisionName: e.target.value })
              }
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <option value="" disabled>
                -- Select a Division --
              </option>
              {divisions.map((div) => {
                const isOccupied = !!div.divisionalHead;
                return (
                  <option
                    key={div.division_Id}
                    value={div.division_Name}
                    disabled={isOccupied}
                    className={
                      isOccupied ? "text-red-400 bg-[#1a0f16]" : "text-white"
                    }
                  >
                    {div.division_Name} ({div.division_Id}){" "}
                    {isOccupied ? " - [ Assigned ]" : ""}
                  </option>
                );
              })}
            </select>
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase flex items-center">
              <User size={12} className="mr-1 text-blue-400" /> System Username
              *
            </label>
            <input
              required
              disabled={allOccupied}
              value={headForm.username}
              onChange={(e) =>
                setHeadForm({ ...headForm, username: e.target.value })
              }
              type="text"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white font-mono disabled:opacity-50 disabled:cursor-not-allowed"
              placeholder="e.g. jdoe_head"
            />
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase flex items-center">
              <Lock size={12} className="mr-1 text-blue-400" /> Login Password *
            </label>
            <div className="relative">
              <input
                required
                disabled={allOccupied}
                value={headForm.passwordStr}
                onChange={(e) =>
                  setHeadForm({ ...headForm, passwordStr: e.target.value })
                }
                type={showPassword ? "text" : "password"}
                className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 pr-10 text-sm focus:border-amber-500 outline-none text-white font-mono disabled:opacity-50 disabled:cursor-not-allowed"
                placeholder="Enter secure password"
              />
              <button
                type="button"
                disabled={allOccupied}
                onClick={() => setShowPassword(!showPassword)}
                className="absolute inset-y-0 right-3 flex items-center text-slate-500 hover:text-amber-400 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          <div className="space-y-2 md:col-span-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">
              Official Email *
            </label>
            <input
              required
              disabled={allOccupied}
              value={headForm.email}
              onChange={(e) =>
                setHeadForm({ ...headForm, email: e.target.value })
              }
              type="email"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white disabled:opacity-50 disabled:cursor-not-allowed"
            />
          </div>
        </div>

        <div className="flex justify-end border-t border-[#1a2f5c] pt-6">
          <button
            type="submit"
            disabled={allOccupied}
            className="bg-amber-600 hover:bg-amber-500 disabled:opacity-50 disabled:hover:bg-amber-600 text-white px-8 py-3 rounded-xl font-bold flex items-center shadow-lg shadow-amber-900/40 transition-all"
          >
            <PlusCircle size={18} className="mr-2" /> Register Head
          </button>
        </div>
      </form>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050d1a] text-slate-400 text-xs uppercase tracking-widest">
            <tr>
              <th className="p-4">Name</th>
              <th className="p-4">Username</th>
              <th className="p-4">Division</th>
              <th className="p-4">Email</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#1a2f5c]">
            {heads.map((head) => (
              <tr
                key={head.divisional_Head_Id}
                className="hover:bg-[#132752]/50 transition-all"
              >
                <td className="p-4 font-bold text-white">{head.name}</td>
                <td className="p-4 font-mono font-bold text-blue-400">
                  {head.username}
                </td>
                <td className="p-4">
                  <span className="bg-[#1a2f5c] px-2 py-1 rounded text-amber-400 text-xs border border-amber-500/20">
                    {head.division?.division_Name}
                  </span>
                </td>
                <td className="p-4 text-slate-400">{head.email}</td>
              </tr>
            ))}
            {heads.length === 0 && (
              <tr>
                <td
                  colSpan={4}
                  className="p-8 text-center text-slate-500 font-bold uppercase text-xs"
                >
                  No divisional heads registered.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
