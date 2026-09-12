export function DateChip({ iso }: { iso: string }) {
  const d = new Date(iso);
  const valid = !Number.isNaN(d.getTime());
  return (
    <div className="flex w-11 shrink-0 flex-col items-center rounded-[10px] bg-scheduled-soft py-1.5 text-saffron-ink">
      <span className="text-[10px] font-bold tracking-[0.06em]">
        {valid ? d.toLocaleDateString(undefined, { weekday: "short" }).toUpperCase() : "—"}
      </span>
      <span className="font-heading text-[17px] font-bold leading-none">
        {valid ? d.getDate() : "?"}
      </span>
    </div>
  );
}

export function fmtTime(iso: string) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" });
}

export function fmtDateTime(iso: string) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleString(undefined, { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });
}
