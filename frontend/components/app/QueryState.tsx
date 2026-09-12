"use client";

import type { ReactNode } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";

/** Uniform loading / error / empty handling for react-query lists. */
export function QueryState({
  isLoading,
  isError,
  error,
  refetch,
  isEmpty,
  emptyTitle = "Nothing here yet",
  emptyHint,
  emptyAction,
  rows = 3,
  children,
}: {
  isLoading: boolean;
  isError: boolean;
  error?: unknown;
  refetch?: () => void;
  isEmpty?: boolean;
  emptyTitle?: string;
  emptyHint?: string;
  emptyAction?: ReactNode;
  rows?: number;
  children: ReactNode;
}) {
  if (isLoading) {
    return (
      <div className="flex flex-col gap-3 p-5" aria-busy="true" aria-live="polite">
        {Array.from({ length: rows }).map((_, i) => (
          <div key={i} className="h-12 animate-pulse rounded-lg bg-muted" />
        ))}
      </div>
    );
  }
  if (isError) {
    return (
      <div className="flex flex-col items-center gap-3 px-5 py-10 text-center" role="alert">
        <span className="inline-flex size-10 items-center justify-center rounded-full bg-live-soft text-live">
          <AlertTriangle className="size-5" />
        </span>
        <div className="font-semibold">Couldn&apos;t load this</div>
        <div className="max-w-sm text-sm text-muted-foreground">{errorMessage(error)}</div>
        {refetch && (
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            <RefreshCw data-icon="inline-start" /> Try again
          </Button>
        )}
      </div>
    );
  }
  if (isEmpty) {
    return (
      <div className="flex flex-col items-center gap-2 px-5 py-10 text-center">
        <div className="font-semibold">{emptyTitle}</div>
        {emptyHint && <div className="max-w-sm text-sm text-muted-foreground">{emptyHint}</div>}
        {emptyAction && <div className="mt-2">{emptyAction}</div>}
      </div>
    );
  }
  return <>{children}</>;
}

export function errorMessage(error: unknown): string {
  const ax = error as { message?: string; response?: { status?: number; data?: { detail?: unknown } } };
  const detail = ax?.response?.data?.detail;
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail)) {
    return detail
      .map((d) => (typeof d === "object" && d && "msg" in d ? String((d as { msg: string }).msg) : JSON.stringify(d)))
      .join("; ");
  }
  if (ax?.message === "Network Error") return "Cannot reach the server. Check your connection.";
  if (ax?.response?.status === 403) return "You don't have permission to do that.";
  return ax?.message || "Something went wrong.";
}
