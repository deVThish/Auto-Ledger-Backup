// app/police-dashboard/divisional-heads/page.tsx
"use client";

import React, { useState } from 'react';
import { Users, PlusCircle, Trash2, Edit, Save, MapPin, AlertCircle, CheckCircle2, X, Lock, User } from 'lucide-react';

export default function ManageHeads() {
  const availableDivisions = [
    { id: 'DIV-001', name: 'Colombo South' },
    { id: 'DIV-002', name: 'Galle Division' },
    { id: 'DIV-003', name: 'Kandy Division' },
  ];

  const [heads, setHeads] = useState([
    { id: 1, name: 'Ajith Rohana', username: 'ajith_do', divisionName: 'Colombo South', email: 'ajith@police.lk' },
  ]);

  // Backend Payload format: { divisionName, username, email, name, passwordStr }
  const [headForm, setHeadForm] = useState({ name: '', username: '', divisionName: '', email: '', passwordStr: '' });
  const [editingId, setEditingId] = useState<number | null>(null);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const handleHeadSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // Duplicate Username check
    const isDuplicateUser = heads.some(h => h.username.toLowerCase() === headForm.username.toLowerCase() && h.id !== editingId);
    if (isDuplicateUser) {
      showToast('error', `Username "${headForm.username}" is already taken!`);
      return;
    }

    if (editingId) {
      setHeads(heads.map(h => h.id === editingId ? { ...h, ...headForm } : h));
      setEditingId(null);
      showToast('success', 'Divisional Head updated successfully!');
    } else {
      setHeads([...heads, { id: Date.now(), ...headForm }]);
      showToast('success', 'Divisional Head registered successfully!');
    }
    setHeadForm({ name: '', username: '', divisionName: '', email: '', passwordStr: '' });
  };

  const handleEdit = (head: any) => {
    setHeadForm({ name: head.name, username: head.username, divisionName: head.divisionName, email: head.email, passwordStr: '' });
    setEditingId(head.id);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancelEdit = () => {
    setEditingId(null);
    setHeadForm({ name: '', username: '', divisionName: '', email: '', passwordStr: '' });
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

      <form onSubmit={handleHeadSubmit} className="bg-[#0b1c3b]/60 p-8 rounded-3xl border border-[#1a2f5c] shadow-xl backdrop-blur-sm">
        <h3 className="text-lg font-bold text-amber-500 mb-6 flex items-center">
          <Users className="mr-2" size={18} /> {editingId ? 'Update Divisional Head' : 'Register Divisional Head'}
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Full Name <span className="text-red-500">*</span></label>
            <input required value={headForm.name} onChange={(e) => setHeadForm({...headForm, name: e.target.value})} type="text" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" />
          </div>
          
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase flex items-center">
              <MapPin size={12} className="mr-1 text-amber-500"/> Assigned Division <span className="text-red-500 ml-1">*</span>
            </label>
            <select required value={headForm.divisionName} onChange={(e) => setHeadForm({...headForm, divisionName: e.target.value})} className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white">
              <option value="" disabled>-- Select a Division --</option>
              {availableDivisions.map(div => <option key={div.id} value={div.name}>{div.name}</option>)}
            </select>
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase flex items-center"><User size={12} className="mr-1 text-blue-400"/> System Username <span className="text-red-500 ml-1">*</span></label>
            <input required value={headForm.username} onChange={(e) => setHeadForm({...headForm, username: e.target.value})} type="text" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white font-mono" placeholder="e.g. jdoe_head" />
          </div>
          
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase flex items-center"><Lock size={12} className="mr-1 text-blue-400"/> Login Password {editingId ? '(Leave blank to keep current)' : '<span className="text-red-500 ml-1">*</span>'}</label>
            <input required={!editingId} value={headForm.passwordStr} onChange={(e) => setHeadForm({...headForm, passwordStr: e.target.value})} type="password" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white font-mono" placeholder="Enter secure password" />
          </div>

          <div className="space-y-2 md:col-span-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Official Email <span className="text-red-500">*</span></label>
            <input required value={headForm.email} onChange={(e) => setHeadForm({...headForm, email: e.target.value})} type="email" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" />
          </div>
        </div>
        
        <div className="flex justify-end space-x-4 border-t border-[#1a2f5c] pt-6">
          {editingId && <button type="button" onClick={handleCancelEdit} className="px-6 py-3 rounded-xl font-bold text-sm text-slate-400 hover:text-white hover:bg-[#132752] transition-all">Cancel</button>}
          <button type="submit" className="bg-amber-600 hover:bg-amber-500 text-white px-8 py-3 rounded-xl font-bold flex items-center transition-all shadow-lg shadow-amber-900/40">
            {editingId ? <><Save size={18} className="mr-2" /> Update Head</> : <><PlusCircle size={18} className="mr-2" /> Register Head</>}
          </button>
        </div>
      </form>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050d1a] text-slate-400 text-xs uppercase tracking-widest">
            <tr><th className="p-4">Name</th><th className="p-4">Username</th><th className="p-4">Assigned Division</th><th className="p-4">Email</th><th className="p-4 text-right">Actions</th></tr>
          </thead>
          <tbody className="divide-y divide-[#1a2f5c]">
            {heads.map(head => (
              <tr key={head.id} className="hover:bg-[#132752]/50 transition-all">
                <td className="p-4 font-bold text-white">{head.name}</td>
                <td className="p-4 font-mono font-bold text-blue-400">{head.username}</td>
                <td className="p-4"><span className="bg-[#1a2f5c] px-2 py-1 rounded text-amber-400 text-xs border border-amber-500/20">{head.divisionName}</span></td>
                <td className="p-4 text-slate-400">{head.email}</td>
                <td className="p-4 text-right space-x-2">
                  <button onClick={() => handleEdit(head)} className="p-2 text-blue-400 hover:bg-blue-500/20 rounded-lg"><Edit size={16} /></button>
                  <button onClick={() => { setHeads(heads.filter(h => h.id !== head.id)); showToast('success', 'Deleted successfully'); }} className="p-2 text-red-400 hover:bg-red-500/20 rounded-lg"><Trash2 size={16} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}