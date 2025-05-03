import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Remove output: "export" to enable server-side rendering
  webpack: (config) => {
    config.resolve.fallback = {
      ...config.resolve.fallback,
      fs: false,
      stream: false,
      path: false,
    };
    return config;
  },
  images: {
    domains: ['firebasestorage.googleapis.com'],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'firebasestorage.googleapis.com',
        pathname: '**',
      },
    ],
  },
  async redirects() {
    return [
      {
        source: '/reports',
        destination: '/report',
        permanent: true,
      },
      {
        source: '/reports/:path*',
        destination: '/report/:path*',
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
