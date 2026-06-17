// app/police-dashboard/divisions/page.tsx
"use client";

import React, { useState } from 'react';
import { Map, PlusCircle, Trash2, Edit, Save, AlertCircle, CheckCircle2, X } from 'lucide-react';

export default function ManageDivisions() {
  const [divisions, setDivisions] = useState([
    { id: 1, divisionId: 'DIV-001', divisionName: 'Galle Division' },
    { id: 2, divisionId: 'DIV-002', divisionName: 'Colombo South' },
  ]);

  // Backend payload eke thiyena widiyata divisionId saha divisionName damma
  const [divisionForm, setDivisionForm] = useState({ divisionId: 'DIV-', divisionName: '' });
  const [editingId, setEditingId] = useState<number | null>(null);
  
  // Toast Alert System State (Backend Error Handling custom component)
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000); // Auto hide after 4 seconds
  };

  // Handle Division ID input to ensure "DIV-" prefix is locked and cannot be deleted
  const handleIdChange = (val: string) => {
    if (!val.startsWith('DIV-')) {
      setDivisionForm({ ...divisionForm, divisionId: 'DIV-' });
    } else {
      setDivisionForm({ ...divisionForm, divisionId: val.toUpperCase() });
    }
  };

  const handleDivisionSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // --- STRICT VALIDATION: Must contain "DIV-" followed by at least 3 digits ---
    const idPattern = /^DIV-\d{3,}$/;
    if (!idPattern.test(divisionForm.divisionId)) {
      showToast('error', 'Bad Request: Division ID format is invalid! Must contain "DIV-" followed by at least 3 numbers (e.g., DIV-001).');
      return;
    }

    // --- DUPLICATE CHECK (Simulating Backend 400 BadRequestException) ---
    const isDuplicateId = divisions.some(d => d.divisionId === divisionForm.divisionId && d.id !== editingId);
    const isDuplicateName = divisions.some(d => d.divisionName.toLowerCase() === divisionForm.divisionName.toLowerCase() && d.id !== editingId);

    if (isDuplicateId) {
      showToast('error', `BadRequestException: Division ID "${divisionForm.divisionId}" already exists in the system.`);
      return;
    }
    if (isDuplicateName) {
      showToast('error', `BadRequestException: Division Name "${divisionForm.divisionName}" already exists.`);
      return;
    }

    // If validations pass, save or update data
    if (editingId) {
      setDivisions(divisions.map(d => d.id === editingId ? { ...d, ...divisionForm } : d));
      setEditingId(null);
      showToast('success', 'Division successfully updated!');
    } else {
      setDivisions([...divisions, { id: Date.now(), ...divisionForm }]);
      showToast('success', 'New Police Division created successfully!');
    }
    setDivisionForm({ divisionId: 'DIV-', divisionName: '' });
  };

  const handleEdit = (division: any) => {
    setDivisionForm({ divisionId: division.divisionId, divisionName: division.divisionName });
    setEditingId(division.id);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancelEdit = () => {
    setEditingId(null);
    setDivisionForm({ divisionId: 'DIV-', divisionName: '' });
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-500 relative">
      
      {/* --- LIVE TOAST NOTIFICATION WINDOW (CATCHES 400 ERRORS) --- */}
      {toast && (
        <div className={`fixed top-6 right-6 z-50 flex items-center p-4 rounded-2xl shadow-2xl border backdrop-blur-xl animate-in slide-in-from-top-6 duration-300 max-w-md ${
          toast.type === 'error' 
            ? 'bg-red-950/80 border-red-500/50 text-red-200' 
            : 'bg-emerald-950/80 border-emerald-500/50 text-emerald-200'
        }`}>
          {toast.type === 'error' ? <AlertCircle className="text-red-400 mr-3 flex-shrink-0" size={20} /> : <CheckCircle2 className="text-emerald-400 mr-3 flex-shrink-0" size={20} />}
          <span className="text-xs font-bold tracking-wide leading-relaxed">{toast.message}</span>
          <button onClick={() => setToast(null)} className="ml-4 p-1 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"><X size={14}/></button>
        </div>
      )}

      {/* FORM LAYOUT */}
      <form onSubmit={handleDivisionSubmit} className="bg-[#0b1c3b]/60 p-8 rounded-3xl border border-[#1a2f5c] shadow-xl backdrop-blur-sm">
        <h3 className="text-lg font-bold text-amber-500 mb-6 flex items-center">
          <Map className="mr-2" size={18} /> {editingId ? 'Update Police Division' : 'Register New Police Division'}
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Division ID <span className="text-red-500">*</span></label>
            <input 
              required 
              value={divisionForm.divisionId} 
              onChange={(e) => handleIdChange(e.target.value)} 
              type="text" 
              placeholder="DIV-001"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white font-mono transition-all focus:ring-1 focus:ring-amber-500/30" 
            />
            <span className="text-[10px] text-slate-500 block font-medium">Must follow "DIV-" prefix with 3 or more digits.</span>
          </div>
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Division Name <span className="text-red-500">*</span></label>
            <input 
              required 
              value={divisionForm.divisionName} 
              onChange={(e) => setDivisionForm({...divisionForm, divisionName: e.target.value})} 
              type="text" 
              placeholder="e.g. Galle Division"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white transition-all focus:ring-1 focus:ring-amber-500/30" 
            />
          </div>
        </div>

        <div className="flex justify-end space-x-4 border-t border-[#1a2f5c] pt-6">
          {editingId && (
            <button type="button" onClick={handleCancelEdit} className="px-6 py-3 rounded-xl font-bold text-sm text-slate-400 hover:text-white hover:bg-[#132752] transition-all">Cancel</button>
          )}
          <button type="submit" className="bg-amber-600 hover:bg-amber-500 text-white px-8 py-3 rounded-xl font-bold flex items-center transition-all shadow-lg shadow-amber-900/40">
            {editingId ? <><Save size={18} className="mr-2" /> Update Division</> : <><PlusCircle size={18} className="mr-2" /> Register Division</>}
          </button>
        </div>
      </form>

      {/* DATA TABLE */}
      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050d1a] text-slate-400 text-xs uppercase tracking-widest">
            <tr>
              <th className="p-4">Division ID</th>
              <th className="p-4">Division Name</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#1a2f5c]">
            {divisions.map(division => (
              <tr key={division.id} className="hover:bg-[#132752]/50 transition-all">
                <td className="p-4 font-mono font-bold text-amber-500">{division.divisionId}</td>
                <td className="p-4 font-bold text-white">{division.divisionName}</td>
                <td className="p-4 text-right space-x-2">
                  <button onClick={() => handleEdit(division)} className="p-2 text-blue-400 hover:bg-blue-500/20 rounded-lg transition-colors"><Edit size={16} /></button>
                  <button onClick={() => setDivisions(divisions.filter(d => d.id !== division.id))} className="p-2 text-red-400 hover:bg-red-500/20 rounded-lg transition-colors"><Trash2 size={16} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}