import type { NextConfig } from "next";
import withPWAInit from "next-pwa";

const withPWA = withPWAInit({
  dest: "public",
  disable: process.env.NODE_ENV === "development",
  register: true,
  skipWaiting: true,
  runtimeCaching: [
    {
      urlPattern: /^https?:\/\/.*\/api\/.*/i,
      handler: "NetworkFirst",
      options: {
        cacheName: "api-cache",
        expiration: { maxEntries: 64, maxAgeSeconds: 60 * 60 },
        networkTimeoutSeconds: 10,
      },
    },
    {
      urlPattern: /\.(js|css|png|jpg|jpeg|svg|gif|webp|ico|woff2?)$/i,
      handler: "StaleWhileRevalidate",
      options: {
        cacheName: "static-assets",
        expiration: { maxEntries: 128, maxAgeSeconds: 7 * 24 * 60 * 60 },
      },
    },
  ],
  fallbacks: {
    document: "/offline",
  },
});

const nextConfig: NextConfig = {
  turbopack: {},
};

export default withPWA(nextConfig);
