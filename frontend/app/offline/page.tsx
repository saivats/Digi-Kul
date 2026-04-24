"use client";

export default function OfflinePage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="text-center space-y-4 max-w-md">
        <div className="text-6xl">📡</div>
        <h1 className="text-2xl font-bold tracking-tight">
          You&apos;re Offline
        </h1>
        <p className="text-muted-foreground">
          It looks like you&apos;ve lost your internet connection. Digi-Kul will
          automatically reconnect when your network is back.
        </p>
        <button
          onClick={() => window.location.reload()}
          className="inline-flex items-center justify-center rounded-md bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
        >
          Try Again
        </button>
      </div>
    </div>
  );
}
