"use client";

import React, { useState, useEffect } from "react";
import {
  ShieldAlert,
  PlusCircle,
  Edit,
  Save,
  AlertCircle,
  CheckCircle2,
  X,
  ChevronLeft,
  ChevronRight,
  Search,
  Power, // <-- අලුතින් add කරපු Icon එක
} from "lucide-react";
import { api } from "@/lib/api";

interface OffenseBackend {
  offense_Id: string;
  code: string;
  name: string;
  points_Value: number;
  amount: number;
  is_Court_Case: boolean;
}

interface Offense {
  id: string;
  code: string;
  name: string;
  points: number;
  amount: number;
  isCourtCase: boolean;
}

interface ApiError {
  response?: {
    data?: {
      message?: string;
    };
  };
}

export default function ManageOffenses() {
  const [fines, setFines] = useState<Offense[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [fineForm, setFineForm] = useState({
    code: "",
    name: "",
    points: "",
    amount: "",
    isCourtCase: false,
  });
  const [editingId, setEditingId] = useState<string | null>(null);
  const [toast, setToast] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;

  const showToast = (type: "success" | "error", message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const loadFines = async () => {
    try {
      const res = await api.get<OffenseBackend[]>("/fines/offenses");
      const mapped = res.data.map((o) => ({
        id: o.offense_Id,
        code: o.code,
        name: o.name,
        points: o.points_Value,
        amount: o.amount,
        isCourtCase: Boolean(o.is_Court_Case),
      }));
      setFines(mapped.reverse());
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    async function fetchOffenses() {
      await loadFines();
    }
    void fetchOffenses();
  }, []);

  const handleFineSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const payload = {
        code: fineForm.code,
        name: fineForm.name,
        points: Number(fineForm.points),
        amount: Number(fineForm.amount),
        isCourtCase: Boolean(fineForm.isCourtCase),
      };

      if (editingId) {
        await api.patch(`/fines/offenses/${editingId}`, payload);
        showToast("success", "Traffic Offense Updated Successfully!");
        setEditingId(null);
      } else {
        await api.post("/fines/offenses", payload);
        showToast("success", "New Traffic Offense Added Successfully!");
        setCurrentPage(1);
      }

      setFineForm({
        code: "",
        name: "",
        points: "",
        amount: "",
        isCourtCase: false,
      });
      await loadFines();
    } catch (err: unknown) {
      const error = err as ApiError;
      showToast(
        "error",
        error.response?.data?.message ||
          "Error saving offense. Code might already exist.",
      );
    }
  };

  const handleEdit = (fine: Offense) => {
    setFineForm({
      code: fine.code,
      name: fine.name,
      points: fine.points.toString(),
      amount: fine.amount.toString(),
      isCourtCase: Boolean(fine.isCourtCase),
    });
    setEditingId(fine.id);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // Toggle Active/Disable action
  const handleToggleActive = async (id: string) => {
    if (
      !window.confirm(
        "Are you sure you want to change the status of this offense?",
      )
    )
      return;
    try {
      await api.patch(`/fines/offenses/${id}/toggle`);
      showToast("success", "Offense status updated successfully");
      await loadFines();
    } catch (err: unknown) {
      const error = err as ApiError;
      showToast(
        "error",
        error.response?.data?.message || "Error updating status",
      );
    }
  };

  const handleCancelEdit = () => {
    setEditingId(null);
    setFineForm({
      code: "",
      name: "",
      points: "",
      amount: "",
      isCourtCase: false,
    });
  };

  const filteredFines = fines.filter(
    (f) =>
      f.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      f.name.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredFines.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredFines.length / itemsPerPage);

  const paginate = (pageNumber: number) => setCurrentPage(pageNumber);

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-8 duration-500 relative pb-10">
      {toast && (
        <div
          className={`fixed top-6 right-6 z-50 flex items-center p-4 rounded-2xl shadow-2xl border backdrop-blur-xl animate-in slide-in-from-top-6 duration-300 max-w-md ${toast.type === "error" ? "bg-red-950/90 border-red-500/50 text-red-200" : "bg-emerald-950/90 border-emerald-500/50 text-emerald-200"}`}
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
          <span className="text-sm font-semibold tracking-wide leading-relaxed">
            {toast.message}
          </span>
          <button
            onClick={() => setToast(null)}
            className="ml-4 p-1 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"
          >
            <X size={16} />
          </button>
        </div>
      )}

      <div className="flex flex-col md:flex-row justify-between items-start md:items-center bg-[#0b1c3b]/40 p-6 rounded-3xl border border-[#1a2f5c] backdrop-blur-sm gap-4">
        <div>
          <h2 className="text-2xl font-black text-white flex items-center">
            <ShieldAlert className="mr-3 text-amber-500" size={28} /> Manage
            Offenses
          </h2>
          <p className="text-sm text-slate-400 mt-1">
            Add, update, or toggle traffic violations and fine configurations.
          </p>
        </div>
      </div>

      <form
        onSubmit={handleFineSubmit}
        className="bg-gradient-to-br from-[#0b1c3b]/80 to-[#050d1a]/80 p-8 rounded-3xl border border-[#1a2f5c] shadow-2xl backdrop-blur-md relative overflow-hidden"
      >
        <div className="absolute top-0 right-0 w-64 h-64 bg-amber-500/5 rounded-full blur-[80px] pointer-events-none"></div>

        <h3 className="text-sm font-bold text-amber-500 mb-6 uppercase tracking-widest flex items-center relative z-10">
          {editingId
            ? "Editing Existing Offense Configuration"
            : "Register New Offense Configuration"}
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8 relative z-10">
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wider">
              Offense Code *
            </label>
            <input
              required
              disabled={!!editingId}
              value={fineForm.code}
              onChange={(e) =>
                setFineForm({ ...fineForm, code: e.target.value })
              }
              type="text"
              placeholder="O-001"
              className={`w-full bg-[#030508] border border-[#1a2f5c] rounded-xl p-3.5 text-sm focus:border-amber-500 outline-none text-white font-mono shadow-inner ${editingId ? "opacity-50 cursor-not-allowed" : ""}`}
            />
          </div>
          <div className="space-y-2 col-span-2 md:col-span-3">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wider">
              Detailed Description *
            </label>
            <input
              required
              value={fineForm.name}
              onChange={(e) =>
                setFineForm({ ...fineForm, name: e.target.value })
              }
              type="text"
              placeholder="e.g. Speeding over 70kmph within city limits"
              className="w-full bg-[#030508] border border-[#1a2f5c] rounded-xl p-3.5 text-sm focus:border-amber-500 outline-none text-white shadow-inner"
            />
          </div>
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wider">
              Demerit Points *
            </label>
            <input
              required
              min="0"
              value={fineForm.points}
              onChange={(e) =>
                setFineForm({ ...fineForm, points: e.target.value })
              }
              type="number"
              placeholder="0"
              className="w-full bg-[#030508] border border-[#1a2f5c] rounded-xl p-3.5 text-sm focus:border-amber-500 outline-none text-white shadow-inner"
            />
          </div>
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wider">
              Fine Amount (LKR) *
            </label>
            <input
              required
              min="0"
              value={fineForm.amount}
              onChange={(e) =>
                setFineForm({ ...fineForm, amount: e.target.value })
              }
              type="number"
              placeholder="3000"
              className="w-full bg-[#030508] border border-[#1a2f5c] rounded-xl p-3.5 text-sm focus:border-amber-500 outline-none text-white shadow-inner"
            />
          </div>
          <div className="space-y-2 flex items-center md:col-span-2 pt-6">
            <label className="flex items-center cursor-pointer group bg-[#030508] border border-[#1a2f5c] px-4 py-3.5 rounded-xl w-full sm:w-auto hover:border-amber-500/50 transition-colors">
              <input
                type="checkbox"
                checked={fineForm.isCourtCase}
                onChange={(e) =>
                  setFineForm({ ...fineForm, isCourtCase: e.target.checked })
                }
                className="w-5 h-5 rounded border-slate-600 text-amber-500 bg-[#030508] focus:ring-amber-500"
              />
              <span className="ml-3 text-sm font-bold text-slate-300 group-hover:text-white transition-colors">
                Requires Court Appearance?
              </span>
            </label>
          </div>
        </div>

        <div className="flex justify-end space-x-4 border-t border-[#1a2f5c] pt-6 relative z-10">
          {editingId && (
            <button
              type="button"
              onClick={handleCancelEdit}
              className="px-6 py-3 rounded-xl font-bold text-sm text-slate-400 hover:text-white hover:bg-[#132752] transition-all"
            >
              Cancel Edit
            </button>
          )}
          <button
            type="submit"
            className="bg-amber-600 hover:bg-amber-500 text-white px-8 py-3 rounded-xl font-bold flex items-center transition-all shadow-[0_0_20px_rgba(217,119,6,0.3)] hover:shadow-[0_0_30px_rgba(217,119,6,0.5)] transform hover:-translate-y-0.5"
          >
            {editingId ? (
              <>
                <Save size={18} className="mr-2" /> Update Configuration
              </>
            ) : (
              <>
                <PlusCircle size={18} className="mr-2" /> Save Offense
              </>
            )}
          </button>
        </div>
      </form>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <div className="p-6 border-b border-[#1a2f5c] flex flex-col sm:flex-row justify-between items-center gap-4 bg-[#050d1a]/50">
          <h3 className="text-white font-bold flex items-center text-lg">
            Registered Offenses Database
            <span className="ml-3 bg-[#1a2f5c] text-amber-400 text-xs py-1 px-3 rounded-full font-bold">
              {filteredFines.length} Total
            </span>
          </h3>
          <div className="relative w-full sm:w-72">
            <Search
              className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
              size={16}
            />
            <input
              type="text"
              placeholder="Search by code or name..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full bg-[#030508] border border-[#1a2f5c] rounded-full pl-10 pr-4 py-2 text-sm focus:border-amber-500 outline-none text-white transition-colors"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-[#030508] text-slate-400 text-xs uppercase tracking-widest">
              <tr>
                <th className="p-5 font-semibold">Code</th>
                <th className="p-5 font-semibold">Description</th>
                <th className="p-5 font-semibold">Points</th>
                <th className="p-5 font-semibold">Amount (LKR)</th>
                <th className="p-5 font-semibold">Court</th>
                <th className="p-5 text-right font-semibold">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1a2f5c]">
              {currentItems.map((fine) => (
                <tr
                  key={fine.id}
                  className="hover:bg-[#132752]/50 transition-colors group"
                >
                  <td className="p-5 font-mono font-bold text-amber-500 whitespace-nowrap">
                    {fine.code}
                  </td>
                  <td className="p-5 font-medium text-slate-200">
                    {fine.name}
                  </td>
                  <td className="p-5 whitespace-nowrap">
                    <span className="bg-red-500/10 text-red-400 px-2.5 py-1 rounded-md border border-red-500/20 font-bold text-xs">
                      {fine.points} pts
                    </span>
                  </td>
                  <td className="p-5 font-bold text-slate-200 whitespace-nowrap">
                    {fine.amount.toLocaleString()}
                  </td>
                  <td className="p-5 whitespace-nowrap">
                    {fine.isCourtCase ? (
                      <span className="text-red-400 font-bold text-xs bg-red-950/30 px-2.5 py-1 rounded-md border border-red-900/50">
                        Required
                      </span>
                    ) : (
                      <span className="text-slate-500 font-bold text-xs bg-slate-800/30 px-2.5 py-1 rounded-md border border-slate-700/50">
                        No
                      </span>
                    )}
                  </td>
                  <td className="p-5 text-right space-x-2 whitespace-nowrap">
                    <button
                      onClick={() => handleEdit(fine)}
                      className="p-2 text-blue-400 hover:bg-blue-500/20 hover:text-blue-300 rounded-lg transition-colors"
                      title="Edit Offense"
                    >
                      <Edit size={18} />
                    </button>
                    {/* Changed from Trash2 to Power Icon with Orange color for Toggle Status */}
                    <button
                      onClick={() => handleToggleActive(fine.id)}
                      className="p-2 text-orange-400 hover:bg-orange-500/20 hover:text-orange-300 rounded-lg transition-colors"
                      title="Enable / Disable Offense"
                    >
                      <Power size={18} />
                    </button>
                  </td>
                </tr>
              ))}
              {currentItems.length === 0 && (
                <tr>
                  <td
                    colSpan={6}
                    className="p-12 text-center text-slate-500 font-bold text-sm"
                  >
                    <ShieldAlert
                      size={40}
                      className="mx-auto mb-3 opacity-20"
                    />
                    No offenses found matching your criteria.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {totalPages > 1 && (
          <div className="p-4 border-t border-[#1a2f5c] bg-[#050d1a]/80 flex items-center justify-between">
            <span className="text-xs font-medium text-slate-400">
              Showing <span className="text-white">{indexOfFirstItem + 1}</span>{" "}
              to{" "}
              <span className="text-white">
                {Math.min(indexOfLastItem, filteredFines.length)}
              </span>{" "}
              of <span className="text-white">{filteredFines.length}</span>{" "}
              entries
            </span>
            <div className="flex space-x-2">
              <button
                onClick={() => paginate(currentPage - 1)}
                disabled={currentPage === 1}
                className="p-2 rounded-lg bg-[#132752] text-slate-300 hover:bg-[#1a2f5c] hover:text-white disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft size={16} />
              </button>

              {Array.from({ length: totalPages }, (_, i) => i + 1).map(
                (number) => (
                  <button
                    key={number}
                    onClick={() => paginate(number)}
                    className={`w-8 h-8 rounded-lg text-sm font-bold transition-colors ${currentPage === number ? "bg-amber-600 text-white" : "bg-[#132752] text-slate-300 hover:bg-[#1a2f5c] hover:text-white"}`}
                  >
                    {number}
                  </button>
                ),
              )}

              <button
                onClick={() => paginate(currentPage + 1)}
                disabled={currentPage === totalPages}
                className="p-2 rounded-lg bg-[#132752] text-slate-300 hover:bg-[#1a2f5c] hover:text-white disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
