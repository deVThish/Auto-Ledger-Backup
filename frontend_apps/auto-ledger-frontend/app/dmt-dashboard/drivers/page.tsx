"use client";

import React, { useState, useEffect } from 'react';
import { Users, Search, Eye, X, CreditCard, MapPin, Calendar, Droplet, Car, Bike, Truck, Bus, Tractor, Accessibility, Edit, Save, UploadCloud } from 'lucide-react';

export default function IssuedLicensesPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDriver, setSelectedDriver] = useState<any>(null);
  const [drivers, setDrivers] = useState<any[]>([]);
  const [isEditing, setIsEditing] = useState(false);
  const [editFormData, setEditFormData] = useState<any>(null);

  const vehicleCategoriesList = [
    { class: 'A1', desc: 'Light Motor Cycles', icon: <Bike size={16}/> },
    { class: 'A', desc: 'Motor Cycles', icon: <Bike size={16}/> },
    { class: 'B1', desc: 'Motor Tricycles', icon: <Car size={16}/> },
    { class: 'B', desc: 'Dual Purpose Vehicles', icon: <Car size={16}/> },
    { class: 'B2', desc: 'Light Motor Vehicles', icon: <Car size={16}/> },
    { class: 'C1', desc: 'Light Motor Lorry', icon: <Truck size={16}/> },
    { class: 'C', desc: 'Motor Lorry', icon: <Truck size={16}/> },
    { class: 'CE', desc: 'Heavy Motor Lorry', icon: <Truck size={16}/> },
    { class: 'D1', desc: 'Light Motor Coach', icon: <Bus size={16}/> },
    { class: 'D', desc: 'Motor Coach', icon: <Bus size={16}/> },
    { class: 'DE', desc: 'Heavy Motor Coach', icon: <Bus size={16}/> },
    { class: 'G1', desc: 'Land Tractor', icon: <Tractor size={16}/> },
    { class: 'G', desc: 'Tractor with Trailer', icon: <Tractor size={16}/> },
    { class: 'J', desc: 'Special Purpose Vehicle', icon: <Truck size={16}/> },
    { class: 'H', desc: 'Invalid Carriages', icon: <Accessibility size={16}/> },
  ];

  const defaultDrivers = [
    { id: 1, fullName: 'Nimal Perera', nicNo: '851234567V', dob: '1985-05-12', bloodGroup: 'O+', address: '123 Galle Rd, Colombo 03', licenseNo: 'B5544123', issueDate: '2024-01-10', profilePic: 'https://i.pravatar.cc/150?u=nimal', categories: { 'A1': { checked: true, transmission: 'Manual', issue: '2024-01-10', expiry: '2032-01-10' }, 'B': { checked: true, transmission: 'Auto', issue: '2024-01-10', expiry: '2032-01-10' } } },
    { id: 2, fullName: 'Kasun Silva', nicNo: '921234567V', dob: '1992-08-22', bloodGroup: 'A+', address: '45 Kandy Rd, Peradeniya', licenseNo: 'B5544456', issueDate: '2022-05-11', profilePic: 'https://i.pravatar.cc/150?u=kasun', categories: { 'A': { checked: true, transmission: 'Manual', issue: '2022-05-11', expiry: '2030-05-11' } } },
  ];

  useEffect(() => {
    const localData = localStorage.getItem('dmtDrivers');
    if (localData) setDrivers(JSON.parse(localData));
    else setDrivers(defaultDrivers);
  }, []);

  const openModal = (driver: any) => {
    setSelectedDriver(driver);
    setEditFormData(JSON.parse(JSON.stringify(driver)));
    setIsEditing(false);
  };
  const closeModal = () => { setSelectedDriver(null); setIsEditing(false); };
  const handleEditChange = (field: string, value: any) => setEditFormData({ ...editFormData, [field]: value });
  const handleCategoryEdit = (catClass: string, field: string, value: any) => setEditFormData((prev: any) => ({ ...prev, categories: { ...prev.categories, [catClass]: { ...prev.categories[catClass], [field]: value } } }));
  
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) setEditFormData({ ...editFormData, profilePic: URL.createObjectURL(e.target.files[0]) });
  };

  const saveUpdates = () => {
    const updatedDrivers = drivers.map(d => d.id === editFormData.id ? editFormData : d);
    setDrivers(updatedDrivers);
    localStorage.setItem('dmtDrivers', JSON.stringify(updatedDrivers));
    setSelectedDriver(editFormData);
    setIsEditing(false);
    alert("License Updated Successfully!");
  };

  const filteredDrivers = drivers.filter(d => {
    const searchLower = searchQuery.toLowerCase();
    const nic = (d.nicNo || d.userId || "").toLowerCase();
    const license = (d.licenseNo || "").toLowerCase();
    const name = (d.fullName || "").toLowerCase();
    return nic.includes(searchLower) || license.includes(searchLower) || name.includes(searchLower);
  });

  return (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-700 pb-10">
      <div className="bg-[#0a0f16]/60 border border-white/5 rounded-[2.5rem] p-6 backdrop-blur-2xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.8)] flex flex-col md:flex-row justify-between items-center gap-4 relative overflow-hidden">
        <div className="absolute top-0 left-0 w-64 h-64 bg-cyan-500/5 rounded-full blur-[80px] pointer-events-none"></div>
        <div className="relative z-10">
          <h3 className="text-xl font-bold text-white flex items-center tracking-wide"><Users className="mr-3 text-cyan-400 drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]" size={24} /> Issued Licenses Directory</h3>
          <p className="text-sm text-slate-400 mt-1">Search, view and edit driver records directly.</p>
        </div>
        <div className="relative w-full md:w-96 z-10">
          <Search className="absolute left-4 top-3 text-cyan-500/50" size={18} />
          <input type="text" placeholder="Search by NIC, License No or Name..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="w-full bg-[#030508]/80 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-sm focus:border-cyan-400/50 outline-none text-white placeholder-slate-500 focus:ring-1 focus:ring-cyan-400/20 transition-all"/>
        </div>
      </div>

      <div className="bg-[#0a0f16]/60 border border-white/5 rounded-[2.5rem] overflow-hidden backdrop-blur-2xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050810]/50 text-cyan-500/50 text-[11px] uppercase tracking-[0.2em] border-b border-white/5">
            <tr>
              <th className="p-5 font-black">Driver Name</th>
              <th className="p-5 font-black">NIC</th>
              <th className="p-5 font-black">License No</th>
              <th className="p-5 font-black">Allowed Classes</th>
              <th className="p-5 text-center font-black">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {filteredDrivers.length > 0 ? filteredDrivers.map(driver => (
              <tr key={driver.id} className="hover:bg-white/[0.02] transition-all duration-300 group">
                <td className="p-5 font-bold text-slate-200 flex items-center group-hover:text-white">
                  {driver.profilePic ? (
                    <img src={driver.profilePic} alt={driver.fullName} className="w-9 h-9 rounded-full mr-4 object-cover border border-cyan-500/30 shadow-[0_0_10px_rgba(34,211,238,0.1)]" />
                  ) : (
                    <div className="w-9 h-9 rounded-full mr-4 bg-cyan-900/30 border border-cyan-500/30 flex items-center justify-center font-black text-xs text-cyan-300">{driver.fullName.charAt(0)}</div>
                  )}
                  {driver.fullName}
                </td>
                <td className="p-5 text-slate-400 tracking-wide">{driver.nicNo}</td>
                <td className="p-5 font-mono text-cyan-400/80 font-bold tracking-wider group-hover:text-cyan-300 group-hover:drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]">{driver.licenseNo}</td>
                <td className="p-5">
                  <div className="flex flex-wrap gap-1.5">
                    {Object.entries(driver.categories || {}).filter(([_, data]: any) => data.checked).map(([catClass]) => (
                      <span key={catClass} className="bg-gradient-to-br from-cyan-950/40 to-purple-950/40 text-cyan-200 px-2.5 py-0.5 rounded border border-cyan-500/20 text-[10px] font-bold tracking-wider shadow-[0_0_5px_rgba(34,211,238,0.1)]">{catClass}</span>
                    ))}
                  </div>
                </td>
                <td className="p-5 text-center flex justify-center space-x-2">
                  <button onClick={() => openModal(driver)} className="bg-cyan-950/30 hover:bg-cyan-900/50 text-cyan-400 hover:text-cyan-200 border border-cyan-500/20 hover:border-cyan-400/50 px-4 py-2 rounded-xl font-bold transition-all text-xs flex items-center shadow-[0_0_10px_rgba(34,211,238,0.05)] hover:shadow-[0_0_15px_rgba(34,211,238,0.2)]">
                    <Eye size={14} className="mr-1.5" /> View / Edit
                  </button>
                </td>
              </tr>
            )) : (
              <tr><td colSpan={5} className="p-8 text-center text-slate-500 tracking-widest uppercase text-xs font-bold">No records found.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {/* RARE SCI-FI MODAL */}
      {selectedDriver && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#030407]/90 backdrop-blur-md animate-in fade-in duration-300">
          <div className="bg-[#0a0f16]/95 border border-cyan-500/20 rounded-[2.5rem] w-full max-w-4xl max-h-[90vh] overflow-y-auto shadow-[0_0_50px_rgba(34,211,238,0.1)] custom-scrollbar relative">
            
            <div className="sticky top-0 bg-[#050810]/80 backdrop-blur-xl p-6 border-b border-white/5 flex justify-between items-center z-10">
              <h3 className="text-xl font-black text-white flex items-center tracking-wide drop-shadow-[0_0_5px_rgba(255,255,255,0.2)]">
                <CreditCard className="mr-3 text-cyan-400 drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]"/> 
                {isEditing ? `Edit Record: ${editFormData.licenseNo}` : `Driver File: ${selectedDriver.licenseNo}`}
              </h3>
              <div className="flex items-center space-x-3">
                {!isEditing ? (
                  <button onClick={() => setIsEditing(true)} className="flex items-center px-5 py-2.5 bg-gradient-to-r from-purple-600/20 to-cyan-600/20 border border-cyan-500/30 hover:border-cyan-400/60 text-cyan-200 rounded-xl font-bold text-sm transition-all hover:shadow-[0_0_15px_rgba(34,211,238,0.3)]"><Edit size={16} className="mr-2"/> Edit Profile</button>
                ) : (
                  <>
                    <button onClick={() => setIsEditing(false)} className="px-5 py-2.5 text-slate-400 hover:text-white text-sm font-bold transition-colors">Cancel</button>
                    <button onClick={saveUpdates} className="flex items-center px-5 py-2.5 bg-gradient-to-r from-cyan-400 to-blue-600 hover:from-cyan-300 hover:to-blue-500 text-[#030407] rounded-xl font-black text-sm transition-all shadow-[0_0_15px_rgba(34,211,238,0.4)]"><Save size={16} className="mr-2"/> Save</button>
                  </>
                )}
                <button onClick={closeModal} className="p-2.5 text-slate-400 hover:text-white bg-white/5 rounded-full hover:bg-white/10 transition-colors ml-4 border border-transparent hover:border-white/10"><X size={20}/></button>
              </div>
            </div>

            <div className="p-8 space-y-8 relative">
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[30rem] h-[30rem] bg-cyan-500/5 rounded-full blur-[120px] pointer-events-none"></div>

              <div className="bg-[#050810]/50 border border-white/5 p-6 rounded-[2rem] flex flex-col md:flex-row gap-8 items-center md:items-start relative z-10 shadow-[inset_0_0_20px_rgba(0,0,0,0.5)]">
                
                <div className="relative group">
                  {isEditing ? (
                    <label className="w-36 h-44 border-2 border-dashed border-cyan-500/50 rounded-2xl flex flex-col items-center justify-center bg-[#030508] hover:bg-cyan-900/20 transition-all cursor-pointer overflow-hidden relative shadow-[0_0_15px_rgba(34,211,238,0.1)]">
                      <input type="file" accept="image/*" className="hidden" onChange={handleImageUpload} />
                      {editFormData.profilePic && <img src={editFormData.profilePic} alt="Pic" className="w-full h-full object-cover opacity-40" />}
                      <div className="absolute inset-0 flex flex-col items-center justify-center text-cyan-400 drop-shadow-[0_0_5px_rgba(34,211,238,0.8)]">
                        <UploadCloud size={28} className="mb-2" />
                        <span className="text-[9px] font-black uppercase text-center bg-[#030508]/80 px-3 py-1.5 rounded-lg border border-cyan-500/30 tracking-widest">Change</span>
                      </div>
                    </label>
                  ) : (
                    selectedDriver.profilePic ? (
                      <div className="relative">
                        <div className="absolute inset-0 bg-gradient-to-tr from-cyan-400 to-purple-500 rounded-2xl blur-md opacity-30"></div>
                        <img src={selectedDriver.profilePic} alt={selectedDriver.fullName} className="w-36 h-44 object-cover rounded-2xl border border-white/10 shadow-xl relative z-10" />
                      </div>
                    ) : (
                      <div className="w-36 h-44 bg-[#030508] rounded-2xl border border-white/5 flex flex-col items-center justify-center text-slate-700 shadow-inner">
                        <Users size={48} />
                      </div>
                    )
                  )}
                </div>
                
                <div className="flex-1 grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-5 text-sm w-full">
                  <div className="sm:col-span-2 border-b border-white/5 pb-3">
                    <p className="text-[10px] text-cyan-500/70 uppercase font-bold tracking-widest">Full Name</p>
                    {isEditing ? <input value={editFormData.fullName} onChange={e => handleEditChange('fullName', e.target.value)} className="w-full bg-[#030508] border border-cyan-500/40 rounded-xl p-2.5 mt-1.5 text-cyan-50 outline-none focus:border-cyan-300 focus:shadow-[0_0_10px_rgba(34,211,238,0.2)] transition-all"/> : <p className="font-black text-white text-xl mt-1 tracking-wide">{selectedDriver.fullName}</p>}
                  </div>
                  <div>
                    <p className="text-[10px] text-cyan-500/70 uppercase font-bold tracking-widest">NIC Number</p>
                    {isEditing ? <input value={editFormData.nicNo} onChange={e => handleEditChange('nicNo', e.target.value)} className="w-full bg-[#030508] border border-cyan-500/40 rounded-xl p-2.5 mt-1.5 text-cyan-100 outline-none focus:border-cyan-300 transition-all"/> : <p className="font-bold text-slate-200 text-base mt-1 tracking-wider">{selectedDriver.nicNo}</p>}
                  </div>
                  <div>
                    <p className="text-[10px] text-cyan-500/70 uppercase font-bold tracking-widest">License Number</p>
                    {isEditing ? <input value={editFormData.licenseNo} onChange={e => handleEditChange('licenseNo', e.target.value)} className="w-full bg-[#030508] border border-cyan-500/40 rounded-xl p-2.5 mt-1.5 font-mono text-cyan-300 outline-none focus:border-cyan-300 transition-all"/> : <p className="font-mono font-black text-cyan-400 drop-shadow-[0_0_2px_rgba(34,211,238,0.5)] text-base mt-1">{selectedDriver.licenseNo}</p>}
                  </div>
                  <div>
                    <p className="text-[10px] text-cyan-500/70 uppercase font-bold tracking-widest flex items-center"><Calendar size={12} className="mr-1.5 text-purple-400"/> Date of Birth</p>
                    {isEditing ? <input type="date" value={editFormData.dob} onChange={e => handleEditChange('dob', e.target.value)} className="w-full bg-[#030508] border border-cyan-500/40 rounded-xl p-2.5 mt-1.5 text-cyan-100 outline-none [color-scheme:dark] focus:border-cyan-300 transition-all"/> : <p className="font-bold text-slate-200 mt-1">{selectedDriver.dob}</p>}
                  </div>
                  <div>
                    <p className="text-[10px] text-cyan-500/70 uppercase font-bold tracking-widest flex items-center"><Droplet size={12} className="mr-1.5 text-purple-400"/> Blood Group</p>
                    {isEditing ? (
                      <select value={editFormData.bloodGroup} onChange={e => handleEditChange('bloodGroup', e.target.value)} className="w-full bg-[#030508] border border-cyan-500/40 rounded-xl p-2.5 mt-1.5 text-cyan-300 outline-none focus:border-cyan-300 transition-all">
                        <option>O+</option><option>O-</option><option>A+</option><option>A-</option><option>B+</option><option>B-</option><option>AB+</option><option>AB-</option>
                      </select>
                    ) : <p className="font-bold text-cyan-400 bg-cyan-950/40 px-3 py-1 rounded-lg border border-cyan-500/20 w-fit text-xs mt-1.5 shadow-[0_0_10px_rgba(34,211,238,0.1)]">{selectedDriver.bloodGroup}</p>}
                  </div>
                  <div className="sm:col-span-2">
                    <p className="text-[10px] text-cyan-500/70 uppercase font-bold tracking-widest flex items-center"><MapPin size={12} className="mr-1.5 text-purple-400"/> Permanent Address</p>
                    {isEditing ? <input value={editFormData.address} onChange={e => handleEditChange('address', e.target.value)} className="w-full bg-[#030508] border border-cyan-500/40 rounded-xl p-2.5 mt-1.5 text-cyan-100 outline-none focus:border-cyan-300 transition-all"/> : <p className="font-bold text-slate-300 mt-1">{selectedDriver.address}</p>}
                  </div>
                </div>
              </div>

              <div className="relative z-10">
                <h4 className="text-xs font-bold text-purple-400 uppercase tracking-[0.2em] mb-4 border-b border-white/5 pb-3 flex items-center drop-shadow-md"><Car size={16} className="mr-2 text-cyan-400"/> Authorized Vehicle Categories</h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {vehicleCategoriesList.map((cat) => {
                    const dataObj = isEditing ? editFormData : selectedDriver;
                    const catData = (dataObj.categories || {})[cat.class] || {};
                    const isAuthorized = catData.checked || false;

                    return (
                      <div key={cat.class} className={`border rounded-2xl p-4 flex flex-col justify-between transition-all duration-300 ${isAuthorized ? 'bg-gradient-to-br from-cyan-900/20 to-transparent border-cyan-500/30 shadow-[0_0_15px_rgba(34,211,238,0.05)]' : 'bg-[#050810]/30 border-white/5 opacity-40'} ${isEditing && !isAuthorized ? 'hover:opacity-100 cursor-pointer border-dashed border-cyan-500/30' : ''}`}>
                        <div className="flex justify-between items-start">
                          <div className="flex items-center">
                            {isEditing && (
                               <input type="checkbox" checked={isAuthorized} onChange={e => handleCategoryEdit(cat.class, 'checked', e.target.checked)} className="mr-3 w-4 h-4 rounded border-white/10 text-cyan-500 bg-[#030508] focus:ring-cyan-500" />
                            )}
                            <span className={`w-10 h-10 rounded-xl flex items-center justify-center border transition-all ${isAuthorized ? 'bg-cyan-500/10 text-cyan-300 border-cyan-500/40 shadow-[0_0_10px_rgba(34,211,238,0.2)]' : 'bg-[#030508] text-slate-600 border-transparent'}`}>{cat.icon}</span>
                            <div className="ml-3">
                              <span className={`font-black text-lg block leading-none tracking-wide ${isAuthorized ? 'text-white drop-shadow-[0_0_5px_rgba(255,255,255,0.2)]' : ''}`}>{cat.class}</span>
                              <span className="text-[10px] text-slate-500 block mt-1 tracking-wider">{cat.desc}</span>
                            </div>
                          </div>
                          {isEditing && isAuthorized ? (
                             <select value={catData.transmission || 'Manual'} onChange={e => handleCategoryEdit(cat.class, 'transmission', e.target.value)} className="bg-[#030508] border border-cyan-500/40 text-cyan-300 text-[10px] rounded px-1.5 py-0.5 outline-none font-bold tracking-wider"><option>Manual</option><option>Auto</option></select>
                          ) : (
                             isAuthorized ? <span className="text-[9px] bg-gradient-to-r from-cyan-950/50 to-purple-950/50 text-cyan-300 px-2.5 py-1 rounded-md border border-cyan-500/20 font-black uppercase tracking-[0.1em] shadow-[0_0_5px_rgba(34,211,238,0.1)]">{catData.transmission}</span> : <span className="text-[9px] bg-[#030508] text-slate-600 px-2.5 py-1 rounded-md font-bold uppercase tracking-[0.1em] border border-white/5">None</span>
                          )}
                        </div>
                        {isAuthorized && (
                          <div className="grid grid-cols-2 gap-3 mt-4 pt-4 border-t border-cyan-500/10">
                            <div>
                              <span className="text-cyan-500/50 block text-[9px] uppercase font-bold tracking-widest">Issue Date</span>
                              {isEditing ? <input type="date" value={catData.issue || ''} onChange={e => handleCategoryEdit(cat.class, 'issue', e.target.value)} className="bg-[#030508] border border-cyan-500/40 text-cyan-100 rounded-lg p-1.5 mt-1 w-full outline-none [color-scheme:dark] text-xs"/> : <span className="text-slate-300 font-medium text-xs mt-0.5 block">{catData.issue}</span>}
                            </div>
                            <div>
                              <span className="text-purple-400/70 block text-[9px] uppercase font-bold tracking-widest">Expiry Date</span>
                              {isEditing ? <input type="date" value={catData.expiry || ''} onChange={e => handleCategoryEdit(cat.class, 'expiry', e.target.value)} className="bg-[#030508] border border-purple-500/40 text-cyan-100 rounded-lg p-1.5 mt-1 w-full outline-none [color-scheme:dark] text-xs"/> : <span className="text-purple-400 font-bold text-xs mt-0.5 block drop-shadow-[0_0_2px_rgba(168,85,247,0.5)]">{catData.expiry}</span>}
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

          </div>
        </div>
      )}
    </div>
  );
}