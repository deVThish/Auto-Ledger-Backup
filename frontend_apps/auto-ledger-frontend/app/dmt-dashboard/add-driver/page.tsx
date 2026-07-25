"use client";

import React, { useState, useEffect } from "react";
import Image from "next/image";
import {
  Users,
  CreditCard,
  ShieldCheck,
  X,
  Car,
  Bike,
  Truck,
  Bus,
  Tractor,
  Accessibility,
  UploadCloud,
  RefreshCw,
} from "lucide-react";
import { api } from "@/lib/api";
import { AxiosError } from "axios";

interface CategoryData {
  checked?: boolean;
  issue?: string;
  expiry?: string;
  restriction?: string;
  transmission?: string;
}

interface FormData {
  nicNo: string;
  fullName: string;
  dob: string;
  address: string;
  bloodGroup: string;
  licenseNo: string;
  issueDate: string;
  profilePic: string;
  categories: Record<string, CategoryData>;
}

interface StoredDriver {
  license_Id: string;
  license_No: string;
  nic_No: string;
  full_Name: string;
  address: string;
  blood_Group: string;
  date_of_birth?: string;
  issue_Date?: string;
  image?: string;
  vehicleCategories?: {
    vehicle_Class: string;
    issue_Date?: string;
    expiry_Date?: string;
    restriction?: string;
  }[];
}

interface LicensePayload {
  licenseNo?: string;
  nicNo?: string;
  fullName: string;
  address: string;
  bloodGroup: string;
  dateOfBirth: string;
  issueDate: string;
  image?: string;
  categories: {
    vehicleClass: string;
    issueDate: string;
    expiryDate: string;
    restriction?: string;
  }[];
}

const getInitialFormData = (): FormData => {
  if (typeof window !== "undefined") {
    const editData = localStorage.getItem("editDriver");
    if (editData) {
      const driver: StoredDriver = JSON.parse(editData);
      const mappedCategories: Record<string, CategoryData> = {};
      driver.vehicleCategories?.forEach((cat) => {
        mappedCategories[cat.vehicle_Class] = {
          checked: true,
          issue: cat.issue_Date ? cat.issue_Date.split("T")[0] : "",
          expiry: cat.expiry_Date ? cat.expiry_Date.split("T")[0] : "",
          restriction: cat.restriction || "",
        };
      });
      return {
        nicNo: driver.nic_No,
        fullName: driver.full_Name,
        dob: driver.date_of_birth ? driver.date_of_birth.split("T")[0] : "",
        address: driver.address,
        bloodGroup: driver.blood_Group,
        licenseNo: driver.license_No,
        issueDate: driver.issue_Date ? driver.issue_Date.split("T")[0] : "",
        profilePic: driver.image || "",
        categories: mappedCategories,
      };
    }
  }
  return {
    nicNo: "",
    fullName: "",
    dob: "",
    address: "",
    bloodGroup: "O+",
    licenseNo: "",
    issueDate: "",
    profilePic: "",
    categories: {},
  };
};

const getInitialEditingId = (): string | null => {
  if (typeof window !== "undefined") {
    const editData = localStorage.getItem("editDriver");
    if (editData) {
      const driver: StoredDriver = JSON.parse(editData);
      return driver.license_Id;
    }
  }
  return null;
};

export default function ManageLicensesPage() {
  const [editingId, setEditingId] = useState<string | null>(
    getInitialEditingId,
  );
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [formData, setFormData] = useState<FormData>(getInitialFormData);
  const [errors, setErrors] = useState<{ dob?: string; issueDate?: string }>({});

  useEffect(() => {
    if (typeof window !== "undefined") {
      localStorage.removeItem("editDriver");
    }
  }, []);

  useEffect(() => {
    if (formData.dob) {
      const birthDate = new Date(formData.dob);
      const today = new Date();
      let age = today.getFullYear() - birthDate.getFullYear();
      const m = today.getMonth() - birthDate.getMonth();
      if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
        age--;
      }
      if (age < 18) {
        setErrors((prev) => ({ ...prev, dob: "Driver must be at least 18 years old." }));
      } else {
        setErrors((prev) => ({ ...prev, dob: undefined }));
      }
    }
  }, [formData.dob]);

  useEffect(() => {
    if (formData.issueDate) {
      const selected = new Date(formData.issueDate);
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      if (selected > today) {
        setErrors((prev) => ({ ...prev, issueDate: "Issue date cannot be in the future." }));
      } else {
        setErrors((prev) => ({ ...prev, issueDate: undefined }));
      }
    }
  }, [formData.issueDate]);

  const vehicleCategories = [
    { class: "A1", desc: "Light Motor Cycles", icon: <Bike size={16} /> },
    { class: "A", desc: "Motor Cycles", icon: <Bike size={16} /> },
    { class: "B1", desc: "Motor Tricycles", icon: <Car size={16} /> },
    { class: "B", desc: "Dual Purpose Vehicles", icon: <Car size={16} /> },
    { class: "B2", desc: "Light Motor Vehicles", icon: <Car size={16} /> },
    { class: "C1", desc: "Light Motor Lorry", icon: <Truck size={16} /> },
    { class: "C", desc: "Motor Lorry", icon: <Truck size={16} /> },
    { class: "CE", desc: "Heavy Motor Lorry", icon: <Truck size={16} /> },
    { class: "D1", desc: "Light Motor Coach", icon: <Bus size={16} /> },
    { class: "D", desc: "Motor Coach", icon: <Bus size={16} /> },
    { class: "DE", desc: "Heavy Motor Coach", icon: <Bus size={16} /> },
    { class: "G1", desc: "Land Tractor", icon: <Tractor size={16} /> },
    { class: "G", desc: "Tractor with Trailer", icon: <Tractor size={16} /> },
    { class: "J", desc: "Special Purpose Vehicle", icon: <Truck size={16} /> },
    {
      class: "H",
      desc: "Invalid Carriages",
      icon: <Accessibility size={16} />,
    },
  ];

  const handleCategoryChange = (
    catClass: string,
    field: string,
    value: string | boolean,
  ) => {
    setFormData((prev) => {
      const updated = {
        ...prev,
        categories: {
          ...prev.categories,
          [catClass]: { ...prev.categories[catClass], [field]: value },
        },
      };
      if (field === "issue" && value) {
        const issueDate = new Date(value as string);
        if (!isNaN(issueDate.getTime())) {
          const expiryDate = new Date(issueDate);
          expiryDate.setFullYear(expiryDate.getFullYear() + 8);
          const expiryStr = expiryDate.toISOString().split("T")[0];
          updated.categories[catClass] = {
            ...updated.categories[catClass],
            expiry: expiryStr,
          };
        }
      }
      return updated;
    });
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setImageFile(e.target.files[0]);
      setFormData({
        ...formData,
        profilePic: URL.createObjectURL(e.target.files[0]),
      });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (errors.dob || errors.issueDate) {
      alert("Please fix validation errors before submitting.");
      return;
    }

    setIsSubmitting(true);

    try {
      let finalImageUrl = formData.profilePic;

      if (imageFile) {
        const formDataUpload = new FormData();
        formDataUpload.append("file", imageFile);

        const uploadResponse = await api.post<{ fileUrl: string }>(
          "/license/upload-image",
          formDataUpload,
          {
            headers: { "Content-Type": "multipart/form-data" },
          },
        );
        finalImageUrl = uploadResponse.data.fileUrl;
      }

      const categoryArray = Object.keys(formData.categories)
        .filter((key) => formData.categories[key]?.checked)
        .map((key) => {
          const cat = formData.categories[key];
          return {
            vehicleClass: key,
            issueDate: new Date(cat.issue || "").toISOString(),
            expiryDate: new Date(cat.expiry || "").toISOString(),
            restriction:
              cat.restriction ||
              (cat.transmission === "Auto" ? "AT" : undefined),
          };
        });

      const payload: LicensePayload = {
        fullName: formData.fullName,
        address: formData.address,
        bloodGroup: formData.bloodGroup,
        dateOfBirth: new Date(formData.dob).toISOString(),
        issueDate: new Date(formData.issueDate).toISOString(),
        image: finalImageUrl || undefined,
        categories: categoryArray,
      };

      if (editingId) {
        await api.patch(`/license/${editingId}/update`, payload);
        alert("License Successfully Updated!");
      } else {
        payload.licenseNo = formData.licenseNo;
        payload.nicNo = formData.nicNo;
        await api.post("/license", payload);
        alert("Digital License Successfully Issued!");
      }

      handleClear();
    } catch (err: unknown) {
      console.error(err);
      const error = err as AxiosError<{ message?: string }>;
      alert(
        error.response?.data?.message ||
          "An error occurred while saving the license.",
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClear = () => {
    setEditingId(null);
    setImageFile(null);
    setFormData({
      nicNo: "",
      fullName: "",
      dob: "",
      address: "",
      bloodGroup: "O+",
      licenseNo: "",
      issueDate: "",
      profilePic: "",
      categories: {},
    });
    setErrors({});
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const inputClass =
    "w-full bg-[#030508] border border-white/10 rounded-xl p-3 text-sm focus:border-cyan-400/50 outline-none text-cyan-50 focus:ring-1 focus:ring-cyan-400/30 transition-all";
  const today = new Date().toISOString().split("T")[0];

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-700 pb-10">
      <form
        onSubmit={handleSubmit}
        className="bg-[#0a0f16]/60 p-8 rounded-[2.5rem] border border-white/5 shadow-[0_10px_40px_-10px_rgba(0,0,0,0.8)] backdrop-blur-2xl relative overflow-hidden"
      >
        <div className="absolute top-0 right-0 w-96 h-96 bg-purple-500/5 rounded-full blur-[100px] pointer-events-none"></div>

        <div className="flex justify-between items-center border-b border-white/5 pb-4 mb-6 relative z-10">
          <h3 className="text-xl font-bold text-white flex items-center tracking-wide">
            <CreditCard
              className="mr-3 text-cyan-400 drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]"
              size={20}
            />
            {editingId
              ? "Update Driver License Details"
              : "Issue New Digital License"}
          </h3>
          {editingId && (
            <button
              type="button"
              onClick={handleClear}
              className="text-slate-400 hover:text-cyan-400 flex items-center text-sm font-bold bg-white/[0.02] hover:bg-white/5 px-3 py-1.5 rounded-lg border border-white/5 transition-all"
            >
              <X size={16} className="mr-1" /> Cancel Edit
            </button>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8 relative z-10">
          <div className="flex flex-col items-center space-y-4">
            <h4 className="text-xs font-bold text-purple-400 uppercase tracking-[0.2em] drop-shadow-md">
              <Users size={16} className="inline mr-2 text-cyan-400" />{" "}
              Photograph
            </h4>
            <label className="w-40 h-48 border-2 border-dashed border-cyan-500/30 rounded-[1.5rem] flex flex-col items-center justify-center bg-[#030508]/50 hover:bg-cyan-900/20 transition-all duration-300 cursor-pointer overflow-hidden group shadow-[inset_0_0_20px_rgba(34,211,238,0.05)] hover:shadow-[inset_0_0_20px_rgba(34,211,238,0.15)] hover:border-cyan-400/50">
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={handleImageUpload}
              />
              {formData.profilePic ? (
                <Image
                  src={formData.profilePic}
                  alt="Profile"
                  width={160}
                  height={192}
                  className="w-full h-full object-cover"
                  unoptimized
                />
              ) : (
                <>
                  <UploadCloud
                    size={32}
                    className="text-cyan-500/70 mb-2 group-hover:scale-110 group-hover:text-cyan-400 transition-all duration-300 drop-shadow-[0_0_5px_rgba(34,211,238,0.3)]"
                  />
                  <span className="text-[10px] text-slate-400 font-bold uppercase text-center px-4 tracking-widest group-hover:text-cyan-100">
                    Upload Photo
                  </span>
                </>
              )}
            </label>
          </div>

          <div className="lg:col-span-3 grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4 md:col-span-2">
              <h4 className="text-xs font-bold text-purple-400 uppercase tracking-[0.2em] mb-2 border-b border-white/5 pb-2 drop-shadow-md">
                Driver Details
              </h4>
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-cyan-500/70 uppercase tracking-widest">
                Full Name <span className="text-cyan-400">*</span>
              </label>
              <input
                required
                value={formData.fullName}
                onChange={(e) =>
                  setFormData({ ...formData, fullName: e.target.value })
                }
                type="text"
                className={inputClass}
              />
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-cyan-500/70 uppercase tracking-widest">
                NIC Number <span className="text-cyan-400">*</span>
              </label>
              <input
                required
                value={formData.nicNo}
                onChange={(e) =>
                  setFormData({ ...formData, nicNo: e.target.value })
                }
                type="text"
                disabled={!!editingId}
                className={`${inputClass} ${
                  editingId ? "opacity-50 cursor-not-allowed text-gray-500" : ""
                }`}
              />
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-cyan-500/70 uppercase tracking-widest">
                Date of Birth <span className="text-cyan-400">*</span>
              </label>
              <input
                required
                value={formData.dob}
                onChange={(e) =>
                  setFormData({ ...formData, dob: e.target.value })
                }
                type="date"
                className={`${inputClass} [color-scheme:dark] ${
                  errors.dob ? "border-red-500/50" : ""
                }`}
              />
              {errors.dob && (
                <p className="text-red-400 text-xs mt-1">{errors.dob}</p>
              )}
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-cyan-500/70 uppercase tracking-widest">
                Blood Group <span className="text-cyan-400">*</span>
              </label>
              <select
                required
                value={formData.bloodGroup}
                onChange={(e) =>
                  setFormData({ ...formData, bloodGroup: e.target.value })
                }
                className={inputClass}
              >
                <option>O+</option>
                <option>O-</option>
                <option>A+</option>
                <option>A-</option>
                <option>B+</option>
                <option>B-</option>
                <option>AB+</option>
                <option>AB-</option>
              </select>
            </div>
            <div className="space-y-1 md:col-span-2">
              <label className="text-[10px] font-bold text-cyan-500/70 uppercase tracking-widest">
                Address <span className="text-cyan-400">*</span>
              </label>
              <input
                required
                value={formData.address}
                onChange={(e) =>
                  setFormData({ ...formData, address: e.target.value })
                }
                type="text"
                className={inputClass}
              />
            </div>

            <div className="space-y-4 md:col-span-2 mt-4">
              <h4 className="text-xs font-bold text-purple-400 uppercase tracking-[0.2em] mb-2 border-b border-white/5 pb-2 flex items-center drop-shadow-md">
                <ShieldCheck size={16} className="mr-2 text-cyan-400" /> General
                License Info
              </h4>
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-cyan-500/70 uppercase tracking-widest">
                License Number <span className="text-cyan-400">*</span>
              </label>
              <input
                required
                value={formData.licenseNo}
                onChange={(e) =>
                  setFormData({ ...formData, licenseNo: e.target.value })
                }
                type="text"
                disabled={!!editingId}
                className={`${inputClass} font-mono tracking-wider font-bold text-cyan-300 drop-shadow-[0_0_2px_rgba(34,211,238,0.5)] ${
                  editingId ? "opacity-50 cursor-not-allowed" : ""
                }`}
              />
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-cyan-500/70 uppercase tracking-widest">
                Initial Issue Date <span className="text-cyan-400">*</span>
              </label>
              <input
                required
                value={formData.issueDate}
                onChange={(e) =>
                  setFormData({ ...formData, issueDate: e.target.value })
                }
                type="date"
                max={today}
                className={`${inputClass} [color-scheme:dark] ${
                  errors.issueDate ? "border-red-500/50" : ""
                }`}
              />
              {errors.issueDate && (
                <p className="text-red-400 text-xs mt-1">{errors.issueDate}</p>
              )}
            </div>
          </div>
        </div>

        <div className="mt-8 pt-6 border-t border-white/5 relative z-10">
          <h4 className="text-xs font-bold text-purple-400 uppercase tracking-[0.2em] mb-4 flex items-center drop-shadow-md">
            <Car size={16} className="mr-2 text-cyan-400" /> Allowed Vehicle
            Categories
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {vehicleCategories.map((cat) => {
              const catData = formData.categories[cat.class] || {};
              const isChecked = catData.checked || false;
              return (
                <div
                  key={cat.class}
                  className={`border rounded-[1.2rem] p-4 transition-all duration-500 ${
                    isChecked
                      ? "bg-gradient-to-br from-cyan-900/20 to-transparent border-cyan-500/30 shadow-[0_0_15px_rgba(34,211,238,0.1)]"
                      : "bg-[#050810]/50 border-white/5 hover:border-white/10"
                  }`}
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <label className="flex items-center cursor-pointer group flex-1">
                      <input
                        type="checkbox"
                        checked={isChecked}
                        onChange={(e) =>
                          handleCategoryChange(
                            cat.class,
                            "checked",
                            e.target.checked,
                          )
                        }
                        className="w-5 h-5 rounded border-white/10 text-cyan-400 bg-[#030508] focus:ring-cyan-500 focus:ring-offset-[#050810]"
                      />
                      <div className="ml-4 flex items-center">
                        <span
                          className={`w-10 h-10 rounded-xl flex items-center justify-center border transition-all duration-300 ${
                            isChecked
                              ? "bg-cyan-500/20 text-cyan-300 border-cyan-500/40 shadow-[0_0_10px_rgba(34,211,238,0.2)]"
                              : "bg-[#0a0f16] text-slate-500 border-white/5"
                          }`}
                        >
                          {cat.icon}
                        </span>
                        <div className="ml-3">
                          <span
                            className={`font-black text-lg tracking-wide ${
                              isChecked
                                ? "text-white drop-shadow-[0_0_5px_rgba(255,255,255,0.3)]"
                                : "text-slate-400"
                            }`}
                          >
                            {cat.class}
                          </span>
                          <span className="block text-[11px] text-slate-500">
                            {cat.desc}
                          </span>
                        </div>
                      </div>
                    </label>
                    {isChecked && (
                      <select
                        value={catData.transmission || "Manual"}
                        onChange={(e) =>
                          handleCategoryChange(
                            cat.class,
                            "transmission",
                            e.target.value,
                          )
                        }
                        className="bg-[#030508] border border-cyan-500/30 text-cyan-300 text-xs rounded-lg px-2 py-1.5 outline-none focus:border-cyan-400"
                      >
                        <option value="Manual">Manual</option>
                        <option value="Auto">Auto</option>
                      </select>
                    )}
                  </div>
                  {isChecked && (
                    <div className="grid grid-cols-2 gap-4 mt-4 pt-4 border-t border-cyan-500/10">
                      <div className="space-y-1">
                        <label className="text-[9px] font-bold text-cyan-500/70 uppercase tracking-widest">
                          Issue Date
                        </label>
                        <input
                          required
                          type="date"
                          value={catData.issue || ""}
                          onChange={(e) =>
                            handleCategoryChange(
                              cat.class,
                              "issue",
                              e.target.value,
                            )
                          }
                          max={today} // <-- FUTURE DATES DISABLED
                          className="w-full bg-[#030508] border border-cyan-500/20 rounded-lg px-2 py-1.5 text-xs text-cyan-50 outline-none [color-scheme:dark]"
                        />
                      </div>
                      <div className="space-y-1">
                        <label className="text-[9px] font-bold text-cyan-500/70 uppercase tracking-widest">
                          Expiry Date
                        </label>
                        <input
                          required
                          type="date"
                          value={catData.expiry || ""}
                          readOnly
                          className="w-full bg-[#030508] border border-cyan-500/20 rounded-lg px-2 py-1.5 text-xs text-slate-400 outline-none cursor-not-allowed"
                        />
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        <div className="flex justify-end space-x-4 pt-8 mt-8 border-t border-white/5 relative z-10">
          <button
            type="button"
            onClick={handleClear}
            className="px-6 py-3 rounded-xl font-bold text-sm text-slate-400 hover:text-cyan-300 bg-white/[0.02] hover:bg-white/5 border border-transparent hover:border-white/10 transition-all flex items-center"
          >
            <RefreshCw size={16} className="mr-2" /> Clear Form
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="bg-gradient-to-r from-cyan-400 to-blue-600 hover:from-cyan-300 hover:to-blue-500 text-[#030407] px-8 py-3 rounded-xl font-black flex items-center transition-all duration-300 shadow-[0_0_20px_rgba(34,211,238,0.3)] hover:shadow-[0_0_25px_rgba(34,211,238,0.5)] transform hover:-translate-y-0.5 disabled:opacity-50"
          >
            <ShieldCheck size={18} className="mr-2" />
            {isSubmitting
              ? "Processing..."
              : editingId
                ? "Update"
                : "Issue Digital License"}
          </button>
        </div>
      </form>
    </div>
  );
}