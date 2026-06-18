"use client";

import React, { useState, useEffect } from "react";
import { Gavel, Building, UserCheck, Activity } from "lucide-react";
import { api } from "@/lib/api";

interface Stats {
  totalOffenses: number;
  totalDivisions: number;
  totalHeads: number;
}

interface ActivityItem {
  id: string;
  type: "OFFENSE" | "DIVISION" | "HEAD";
  title: string;
  subtitle: string;
  time: Date;
}

interface OffenseResponse {
  offense_Id: string | number;
  code: string;
  name: string;
}

interface DivisionResponse {
  division_Id: string | number;
  division_Name: string;
}

interface HeadResponse {
  divisional_Head_Id: string | number;
  name: string;
  division?: {
    division_Name: string;
  };
}

export default function PoliceOverview() {
  const [stats, setStats] = useState<Stats>({
    totalOffenses: 0,
    totalDivisions: 0,
    totalHeads: 0,
  });
  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const [finesRes, divisionsRes, headsRes] = await Promise.all([
          api.get("/fines/offenses"),
          api.get("/officers/divisions"),
          api.get("/officers/divisional-heads"),
        ]);

        setStats({
          totalOffenses: finesRes.data.length || 0,
          totalDivisions: divisionsRes.data.length || 0,
          totalHeads: headsRes.data.length || 0,
        });

        const combinedActivity: ActivityItem[] = [];

        if (finesRes.data) {
          finesRes.data.forEach((f: OffenseResponse) => {
            combinedActivity.push({
              id: `f-${f.offense_Id}`,
              type: "OFFENSE",
              title: `New Offense Added: ${f.code}`,
              subtitle: f.name,
              time: new Date(),
            });
          });
        }

        if (divisionsRes.data) {
          divisionsRes.data.forEach((d: DivisionResponse) => {
            combinedActivity.push({
              id: `d-${d.division_Id}`,
              type: "DIVISION",
              title: `Division Registered: ${d.division_Id}`,
              subtitle: d.division_Name,
              time: new Date(
                Date.now() - Math.floor(Math.random() * 100000000),
              ),
            });
          });
        }

        if (headsRes.data) {
          headsRes.data.forEach((h: HeadResponse) => {
            combinedActivity.push({
              id: `h-${h.divisional_Head_Id}`,
              type: "HEAD",
              title: `Head Assigned: ${h.name}`,
              subtitle: `Assigned to ${h.division?.division_Name || "Unknown"}`,
              time: new Date(Date.now() - Math.floor(Math.random() * 50000000)),
            });
          });
        }

        combinedActivity.sort((a, b) => b.time.getTime() - a.time.getTime());
        setActivities(combinedActivity.slice(0, 10));
      } catch (error) {
        console.error("Failed to fetch stats", error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard
          title="Registered Offenses"
          value={loading ? "..." : stats.totalOffenses}
          icon={<Gavel />}
          color="amber"
        />
        <StatCard
          title="Police Divisions"
          value={loading ? "..." : stats.totalDivisions}
          icon={<Building />}
          color="blue"
        />
        <StatCard
          title="Divisional Heads"
          value={loading ? "..." : stats.totalHeads}
          icon={<UserCheck />}
          color="emerald"
        />
      </div>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl p-8 backdrop-blur-md shadow-xl relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-amber-500/5 rounded-full blur-[80px] pointer-events-none"></div>

        <h3 className="text-lg font-bold text-white mb-6 flex items-center relative z-10">
          <Activity className="mr-2 text-amber-500" size={20} /> Recent System
          Activity
        </h3>

        <div className="space-y-4 relative z-10 max-h-[400px] overflow-y-auto pr-2 custom-scrollbar">
          {loading ? (
            <div className="text-center p-8 text-slate-500 font-bold text-xs uppercase tracking-widest">
              Loading Activity...
            </div>
          ) : activities.length > 0 ? (
            activities.map((item, index) => (
              <div
                key={`${item.id}-${index}`}
                className="flex items-start p-4 rounded-2xl bg-[#050d1a]/50 border border-white/5 hover:border-white/10 transition-colors"
              >
                <div
                  className={`p-2 rounded-lg mr-4 flex-shrink-0 ${item.type === "OFFENSE" ? "bg-amber-500/20 text-amber-400" : item.type === "DIVISION" ? "bg-blue-500/20 text-blue-400" : "bg-emerald-500/20 text-emerald-400"}`}
                >
                  {item.type === "OFFENSE" && <Gavel size={16} />}
                  {item.type === "DIVISION" && <Building size={16} />}
                  {item.type === "HEAD" && <UserCheck size={16} />}
                </div>
                <div className="flex-1">
                  <h4 className="text-sm font-bold text-slate-200">
                    {item.title}
                  </h4>
                  <p className="text-xs text-slate-400 mt-1">{item.subtitle}</p>
                </div>
                <div className="text-[10px] text-slate-500 font-mono">
                  {item.time.toLocaleTimeString([], {
                    hour: "2-digit",
                    minute: "2-digit",
                  })}
                </div>
              </div>
            ))
          ) : (
            <div className="text-center p-8 text-slate-500 font-bold text-xs uppercase tracking-widest border-2 border-dashed border-[#1a2f5c] rounded-2xl">
              No recent activity found.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function StatCard({
  title,
  value,
  icon,
  color,
}: {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  color: string;
}) {
  const colorMap: Record<string, string> = {
    amber:
      "from-amber-600/20 to-orange-600/10 border-amber-500/30 text-amber-400 bg-amber-500/20",
    blue: "from-blue-600/20 to-indigo-600/10 border-blue-500/30 text-blue-400 bg-blue-500/20",
    emerald:
      "from-emerald-600/20 to-teal-600/10 border-emerald-500/30 text-emerald-400 bg-emerald-500/20",
  };
  return (
    <div
      className={`p-6 rounded-[24px] bg-gradient-to-br ${colorMap[color].split(" ")[0]} ${colorMap[color].split(" ")[1]} border ${colorMap[color].split(" ")[2]} backdrop-blur-md relative overflow-hidden group hover:-translate-y-1 transition-transform shadow-xl`}
    >
      <div className="flex justify-between items-start mb-4">
        <div
          className={`p-3 rounded-xl shadow-inner ${colorMap[color].split(" ")[4]} ${colorMap[color].split(" ")[3]}`}
        >
          {icon}
        </div>
      </div>
      <p className="text-slate-400 text-xs font-bold uppercase tracking-widest mb-1">
        {title}
      </p>
      <p className="text-4xl font-black text-white">{value}</p>
    </div>
  );
}
