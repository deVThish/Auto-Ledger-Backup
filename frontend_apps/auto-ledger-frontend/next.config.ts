import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: process.env.NEXT_PUBLIC_S3_HOSTNAME || "localhost",
        port: "",
        pathname: "/**",
      },
    ],
  },
};

export default nextConfig;
