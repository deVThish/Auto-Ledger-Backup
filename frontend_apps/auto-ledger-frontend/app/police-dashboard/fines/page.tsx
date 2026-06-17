// app/police-dashboard/fines/page.tsx
"use client";

import React, { useState } from 'react';
import { Gavel, PlusCircle, Trash2, Edit, Save, AlertCircle, CheckCircle2, X } from 'lucide-react';

export default function ManageFines() {
  const [fines, setFines] = useState([
    { id: 1, code: 'SPD-01', name: 'Speeding over 70kmph', points: 4, amount: 3000, isCourtCase: false },
    { id: 2, code: 'DRK-02', name: 'Driving under influence', points: 10, amount: 25000, isCourtCase: true },
  ]);

  // Exact keys matched for Backend API POST /fines/offenses
  const [fineForm, setFineForm] = useState({ code: '', name: '', points: '', amount: '', isCourtCase: false });
  const [editingId, setEditingId] = useState<number | null>(null);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const handleFineSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // Duplicate Code check
    const isDuplicate = fines.some(f => f.code.toLowerCase() === fineForm.code.toLowerCase() && f.id !== editingId);
    if (isDuplicate) {
      showToast('error', `BadRequest: Offense Code "${fineForm.code}" already exists!`);
      return;
    }

    if (editingId) {
      setFines(fines.map(f => f.id === editingId ? { ...f, ...fineForm, points: Number(fineForm.points), amount: Number(fineForm.amount) } : f));
      setEditingId(null);
      showToast('success', 'Traffic Offense Updated Successfully!');
    } else {
      const newFine = { id: Date.now(), ...fineForm, points: Number(fineForm.points), amount: Number(fineForm.amount) };
      setFines([...fines, newFine]);
      showToast('success', 'New Traffic Offense Added Successfully!');
    }
    setFineForm({ code: '', name: '', points: '', amount: '', isCourtCase: false });
  };

  const handleEdit = (fine: any) => {
    setFineForm({ code: fine.code, name: fine.name, points: fine.points.toString(), amount: fine.amount.toString(), isCourtCase: fine.isCourtCase });
    setEditingId(fine.id);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancelEdit = () => {
    setEditingId(null);
    setFineForm({ code: '', name: '', points: '', amount: '', isCourtCase: false });
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-500 relative">
      
      {toast && (
        <div className={`fixed top-6 right-6 z-50 flex items-center p-4 rounded-2xl shadow-2xl border backdrop-blur-xl animate-in slide-in-from-top-6 duration-300 max-w-md ${toast.type === 'error' ? 'bg-red-950/80 border-red-500/50 text-red-200' : 'bg-emerald-950/80 border-emerald-500/50 text-emerald-200'}`}>
          {toast.type === 'error' ? <AlertCircle className="text-red-400 mr-3 flex-shrink-0" size={20} /> : <CheckCircle2 className="text-emerald-400 mr-3 flex-shrink-0" size={20} />}
          <span className="text-xs font-bold tracking-wide leading-relaxed">{toast.message}</span>
          <button onClick={() => setToast(null)} className="ml-4 p-1 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"><X size={14}/></button>
        </div>
      )}

      <form onSubmit={handleFineSubmit} className="bg-[#0b1c3b]/60 p-8 rounded-3xl border border-[#1a2f5c] shadow-xl backdrop-blur-sm">
        <h3 className="text-lg font-bold text-amber-500 mb-6 flex items-center">
          <Gavel className="mr-2" size={18} /> {editingId ? 'Update Traffic Offense' : 'Add New Traffic Offense (Fine)'}
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Offense Code <span className="text-red-500">*</span></label>
            <input required value={fineForm.code} onChange={(e) => setFineForm({...fineForm, code: e.target.value})} type="text" placeholder="O-001" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white font-mono" />
          </div>
          <div className="space-y-2 col-span-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Offense Description <span className="text-red-500">*</span></label>
            <input required value={fineForm.name} onChange={(e) => setFineForm({...fineForm, name: e.target.value})} type="text" placeholder="e.g. Speeding over 70kmph" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" />
          </div>
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Demerit Points <span className="text-red-500">*</span></label>
            <input required min="0" value={fineForm.points} onChange={(e) => setFineForm({...fineForm, points: e.target.value})} type="number" placeholder="0" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" />
          </div>
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Fine Amount (LKR) <span className="text-red-500">*</span></label>
            <input required min="0" value={fineForm.amount} onChange={(e) => setFineForm({...fineForm, amount: e.target.value})} type="number" placeholder="3000" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" />
          </div>
          <div className="space-y-2 flex items-center md:col-span-2 mt-6">
            <label className="flex items-center cursor-pointer group">
              <input type="checkbox" checked={fineForm.isCourtCase} onChange={(e) => setFineForm({...fineForm, isCourtCase: e.target.checked})} className="w-5 h-5 rounded border-slate-600 text-amber-500 bg-[#050d1a] focus:ring-amber-500" />
              <span className="ml-3 text-sm font-bold text-slate-300 group-hover:text-white transition-colors">Requires Court Appearance?</span>
            </label>
          </div>
        </div>
        <div className="flex justify-end space-x-4 border-t border-[#1a2f5c] pt-6">
          {editingId && <button type="button" onClick={handleCancelEdit} className="px-6 py-3 rounded-xl font-bold text-sm text-slate-400 hover:text-white hover:bg-[#132752] transition-all">Cancel</button>}
          <button type="submit" className="bg-amber-600 hover:bg-amber-500 text-white px-8 py-3 rounded-xl font-bold flex items-center transition-all shadow-lg shadow-amber-900/40">
            {editingId ? <><Save size={18} className="mr-2" /> Update Offense</> : <><PlusCircle size={18} className="mr-2" /> Save Offense</>}
          </button>
        </div>
      </form>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050d1a] text-slate-400 text-xs uppercase tracking-widest">
            <tr><th className="p-4">Code</th><th className="p-4">Description</th><th className="p-4">Points</th><th className="p-4">Amount (LKR)</th><th className="p-4">Court</th><th className="p-4 text-right">Actions</th></tr>
          </thead>
          <tbody className="divide-y divide-[#1a2f5c]">
            {fines.map(fine => (
              <tr key={fine.id} className="hover:bg-[#132752]/50 transition-all">
                <td className="p-4 font-mono font-bold text-amber-500">{fine.code}</td>
                <td className="p-4 font-bold text-white">{fine.name}</td>
                <td className="p-4"><span className="bg-red-500/10 text-red-500 px-2 py-1 rounded border border-red-500/20 font-bold">{fine.points} pts</span></td>
                <td className="p-4 font-bold text-slate-200">{fine.amount.toLocaleString()}</td>
                <td className="p-4">{fine.isCourtCase ? <span className="text-red-500 font-bold">Yes</span> : <span className="text-slate-400 font-bold">No</span>}</td>
                <td className="p-4 text-right space-x-2">
                  <button onClick={() => handleEdit(fine)} className="p-2 text-blue-400 hover:bg-blue-500/20 rounded-lg"><Edit size={16} /></button>
                  <button onClick={() => { setFines(fines.filter(f => f.id !== fine.id)); showToast('success', 'Deleted successfully'); }} className="p-2 text-red-400 hover:bg-red-500/20 rounded-lg"><Trash2 size={16} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}