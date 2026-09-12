import { cn } from "@/lib/utils";

export type Status =
  | "live"
  | "scheduled"
  | "ended"
  | "cancelled"
  | "completed"
  | "offline"
  | "online"
  | "active"
  | "inactive"
  | string;

const STYLES: Record<string, { cls: string; label: string; dot?: boolean; pulse?: boolean }> = {
  live: { cls: "bg-live-soft text-live", label: "Live", dot: true, pulse: true },
  scheduled: { cls: "bg-scheduled-soft text-saffron-ink", label: "Scheduled", dot: true },
  ended: { cls: "bg-ended-soft text-ended", label: "Ended", dot: true },
  completed: { cls: "bg-ended-soft text-ended", label: "Completed", dot: true },
  cancelled: { cls: "bg-ended-soft text-ended", label: "Cancelled", dot: true },
  offline: { cls: "bg-offline-soft text-offline", label: "Offline", dot: true },
  online: { cls: "bg-online-soft text-online", label: "Online", dot: true },
  active: { cls: "bg-online-soft text-online", label: "Active" },
  inactive: { cls: "bg-ended-soft text-ended", label: "Inactive" },
};

export function StatusBadge({
  status,
  label,
  className,
}: {
  status: Status;
  label?: string;
  className?: string;
}) {
  const s = STYLES[status] ?? { cls: "bg-muted text-muted-foreground", label: status };
  return (
    <span className={cn("status-pill uppercase", s.cls, className)}>
      {s.dot &&
        (s.pulse ? (
          <span className="live-dot" />
        ) : (
          <span className="inline-block h-2 w-2 rounded-full bg-current" />
        ))}
      {label ?? s.label}
    </span>
  );
}
