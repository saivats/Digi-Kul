import { cn } from "@/lib/utils";

export function StatCard({
  label,
  value,
  tone = "default",
  hint,
  loading,
}: {
  label: string;
  value: number | string;
  tone?: "default" | "live" | "ink";
  hint?: string;
  loading?: boolean;
}) {
  return (
    <div
      className={cn(
        "panel flex flex-col gap-2.5 p-5",
        tone === "live" && "border-live/25"
      )}
    >
      <div
        className={cn(
          "flex items-center gap-2 text-[13px] font-medium text-muted-foreground",
          tone === "live" && "text-live font-semibold"
        )}
      >
        {tone === "live" && <span className="live-dot" />}
        {label}
      </div>
      {loading ? (
        <div className="h-8 w-16 animate-pulse rounded-md bg-muted" />
      ) : (
        <div
          className={cn(
            "stat-value",
            tone === "live" && "text-live",
            tone === "ink" && "text-ink"
          )}
        >
          {value}
        </div>
      )}
      {hint && <div className="text-xs text-muted-foreground">{hint}</div>}
    </div>
  );
}
