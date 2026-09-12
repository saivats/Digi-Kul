import type { Metadata, Viewport } from "next";
import "./globals.css";
import Providers from "@/components/providers";

export const metadata: Metadata = {
  title: "Digi-Kul — Digital Gurukul",
  description:
    "Bringing quality education to every corner of India, regardless of bandwidth.",
  manifest: "/manifest.json",
};

export const viewport: Viewport = {
  themeColor: "#3730a3",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body className="min-h-full flex flex-col">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
