"use client";

import Image from "next/image";
import { useState, useEffect } from "react";
import { api } from "@/lib/api";

interface ApiData {
  id: string;
  name: string;
}

interface ApiError {
  response?: {
    data?: {
      message?: string;
    };
  };
}

export default function DMTDashboard() {
  const [data, setData] = useState<ApiData[]>([]);

  useEffect(() => {
    let isMounted = true; // Component එක තාම තියෙනවද කියලා බලන්න

    const loadData = async () => {
      try {
        const res = await api.get("/data");
        // Component එක unmount වෙලා නැත්නම් විතරක් state එක update කරනවා
        if (isMounted) {
          setData(res.data);
        }
      } catch (err: unknown) {
        const error = err as ApiError;
        console.error(error.response?.data?.message);
      }
    };

    // ESLint error එක මගහරින්න Promise එකක් ඇතුළෙන් function එක call කරනවා
    Promise.resolve().then(loadData);

    // Component එක අයින් වෙද්දි cleanup කරනවා
    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <div className="p-8">
      <Image src="/logo.png" alt="Logo" width={150} height={150} />

      <div className="mt-8">
        <h2 className="text-xl font-bold mb-4">Dashboard Data</h2>
        {data.length > 0 ? (
          <ul className="list-disc pl-5">
            {data.map((item) => (
              <li key={item.id}>{item.name}</li>
            ))}
          </ul>
        ) : (
          <p className="text-slate-500">No data available or loading...</p>
        )}
      </div>
    </div>
  );
}
