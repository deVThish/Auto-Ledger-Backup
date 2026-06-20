"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import {
  ShieldCheck,
  Eye,
  EyeOff,
  Lock,
  User,
  AlertCircle,
  ArrowRight,
  Database,
} from "lucide-react";
import { api } from "@/lib/api";

interface ApiError {
  response?: {
    data?: {
      message?: string;
    };
  };
}

export default function LoginPage() {
  const router = useRouter();

  const [formData, setFormData] = useState({
    username: "",
    password: "",
    type: "DMT", // Default selected domain
  });

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [greeting, setGreeting] = useState("Welcome");

  // Prevent ESLint state-in-effect error
  useEffect(() => {
    let isMounted = true;
    const determineGreeting = () => {
      if (!isMounted) return;
      const currentHour = new Date().getHours();
      if (currentHour < 12) setGreeting("Good Morning");
      else if (currentHour < 18) setGreeting("Good Afternoon");
      else setGreeting("Good Evening");
    };

    Promise.resolve().then(determineGreeting);
    return () => {
      isMounted = false;
    };
  }, []);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const response = await api.post("/auth/admin/login", formData);
      const data = response.data;

      localStorage.setItem("token", data.accessToken);
      localStorage.setItem("userRole", data.user.role);

      if (data.user.role === "DMT_ADMIN") {
        router.push("/dmt-dashboard");
      } else {
        router.push("/police-dashboard");
      }
    } catch (err: unknown) {
      const error = err as ApiError;
      setError(
        error.response?.data?.message ||
          "Invalid credentials. Please check your Admin Username and Password.",
      );
    } finally {
      setLoading(false);
    }
  };

  const isPolice = formData.type === "POLICE";

  // Dynamic Backgrounds (Very visible changes)
  const bgGradient = isPolice
    ? "bg-gradient-to-br from-amber-100 via-orange-50 to-yellow-100"
    : "bg-gradient-to-br from-cyan-100 via-blue-50 to-sky-100";

  // Dynamic Accents
  const accentColor = isPolice ? "text-amber-600" : "text-cyan-600";
  const ringColor = isPolice
    ? "focus:ring-amber-500/20 focus:border-amber-500"
    : "focus:ring-cyan-500/20 focus:border-cyan-500";
  const buttonColor = isPolice
    ? "bg-amber-600 hover:bg-amber-700"
    : "bg-cyan-600 hover:bg-cyan-700";

  return (
    <div
      className={`min-h-screen flex items-center justify-center p-4 sm:p-8 font-sans transition-colors duration-700 ${bgGradient}`}
    >
      {/* Glassmorphism Card */}
      <div className="w-full max-w-5xl bg-white/60 backdrop-blur-xl border border-white/50 rounded-[2rem] shadow-[0_20px_60px_-15px_rgba(0,0,0,0.1)] flex flex-col md:flex-row overflow-hidden">
        {/* Left Visual Panel */}
        <div className="md:w-5/12 p-10 lg:p-14 flex flex-col justify-between bg-white/40 border-b md:border-b-0 md:border-r border-white/60">
          <div>
            <div
              className={`w-16 h-16 rounded-2xl flex items-center justify-center mb-8 bg-white shadow-sm border border-white/80 transition-colors duration-500 ${accentColor}`}
            >
              <ShieldCheck size={32} />
            </div>
            <h1 className="text-3xl lg:text-4xl font-extrabold text-slate-800 tracking-tight mb-4">
              Admin Web Panel
            </h1>
            <p className="text-slate-600 text-sm leading-relaxed max-w-sm font-medium">
              Secure administration portal for Department of Motor Traffic and
              Sri Lanka Police officials.
            </p>
          </div>

          <div className="mt-12 md:mt-0">
            <div className="bg-white/50 border border-white/60 rounded-2xl p-4 flex items-center space-x-4">
              <div className="p-2 bg-white rounded-lg shadow-sm">
                <Database className={accentColor} size={20} />
              </div>
              <div>
                <p className="text-slate-800 text-xs font-bold tracking-wide">
                  Central Database
                </p>
                <p className="text-slate-500 text-[10px] uppercase tracking-widest font-bold mt-0.5">
                  Live Sync Active
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Right Authentication Panel */}
        <div className="md:w-7/12 p-8 sm:p-12 lg:p-16 flex flex-col justify-center bg-white/80">
          <div className="mb-8">
            <h2 className="text-2xl font-bold text-slate-800 mb-2">
              {greeting}, Admin.
            </h2>
            <p className="text-slate-500 text-sm font-medium">
              Please sign in to access your administrative dashboard.
            </p>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-xl mb-6 text-sm flex items-start">
              <AlertCircle size={18} className="mr-3 mt-0.5 flex-shrink-0" />
              <span className="font-medium">{error}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-5">
            {/* Admin Type Selection */}
            <div className="flex p-1.5 bg-slate-100 rounded-xl border border-slate-200 mb-6">
              <button
                type="button"
                onClick={() => setFormData({ ...formData, type: "DMT" })}
                className={`flex-1 py-2.5 text-sm font-bold rounded-lg transition-all duration-300 ${
                  !isPolice
                    ? "bg-white text-cyan-700 shadow-sm border border-slate-200"
                    : "text-slate-500 hover:text-slate-700"
                }`}
              >
                DMT Admin
              </button>
              <button
                type="button"
                onClick={() => setFormData({ ...formData, type: "POLICE" })}
                className={`flex-1 py-2.5 text-sm font-bold rounded-lg transition-all duration-300 ${
                  isPolice
                    ? "bg-white text-amber-700 shadow-sm border border-slate-200"
                    : "text-slate-500 hover:text-slate-700"
                }`}
              >
                Police Admin
              </button>
            </div>

            {/* Username Input */}
            <div className="space-y-1.5">
              <label className="text-[11px] font-bold text-slate-500 uppercase tracking-widest ml-1">
                Admin Username
              </label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <User size={18} className="text-slate-400" />
                </div>
                <input
                  type="text"
                  required
                  className={`w-full bg-white border border-slate-200 rounded-xl pl-11 pr-4 py-3.5 text-slate-800 text-sm outline-none transition-all focus:ring-4 placeholder-slate-400 ${ringColor}`}
                  placeholder="Enter your username"
                  value={formData.username}
                  onChange={(e) =>
                    setFormData({ ...formData, username: e.target.value })
                  }
                />
              </div>
            </div>

            {/* Password Input */}
            <div className="space-y-1.5">
              <label className="text-[11px] font-bold text-slate-500 uppercase tracking-widest ml-1">
                Admin Password
              </label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <Lock size={18} className="text-slate-400" />
                </div>
                <input
                  type={showPassword ? "text" : "password"}
                  required
                  className={`w-full bg-white border border-slate-200 rounded-xl pl-11 pr-12 py-3.5 text-slate-800 text-sm outline-none transition-all focus:ring-4 font-mono tracking-widest placeholder-slate-400 placeholder:tracking-normal ${ringColor}`}
                  placeholder="••••••••••••"
                  value={formData.password}
                  onChange={(e) =>
                    setFormData({ ...formData, password: e.target.value })
                  }
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-0 pr-4 flex items-center text-slate-400 hover:text-slate-600 transition-colors"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className={`w-full mt-6 py-4 rounded-xl text-white font-bold text-base flex justify-center items-center transition-all duration-300 shadow-md transform hover:-translate-y-0.5 disabled:opacity-70 disabled:cursor-not-allowed disabled:transform-none ${buttonColor}`}
            >
              {loading ? (
                <span className="flex items-center">
                  <span className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-3"></span>
                  Authenticating...
                </span>
              ) : (
                <>
                  Login to Admin Panel
                  <ArrowRight size={18} className="ml-2" />
                </>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
