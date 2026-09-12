"use client";

import { WifiOff } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function OfflinePage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="flex max-w-md flex-col items-center gap-4 text-center">
        <span className="inline-flex size-14 items-center justify-center rounded-full bg-offline-soft text-offline"><WifiOff className="size-7" /></span>
        <h1 className="text-2xl font-bold">You&apos;re offline</h1>
        <p className="text-muted-foreground">Digi-Kul will reconnect when your network is back. Materials you downloaded in the app are still available there.</p>
        <Button onClick={() => window.location.reload()}>Try again</Button>
      </div>
    </div>
  );
}
