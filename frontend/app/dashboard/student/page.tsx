"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Download, FileText, Radio } from "lucide-react";
import { toast } from "sonner";
import { getStudentDashboard, listStudentMaterials, downloadMaterial } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { StatCard } from "@/components/app/StatCard";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState, errorMessage } from "@/components/app/QueryState";
import { DateChip, fmtTime } from "@/components/app/DateChip";
import { Button } from "@/components/ui/button";

interface Lecture { id: string; title: string; scheduled_time: string; duration_minutes?: number; teacher_name?: string; status: string }
interface Material { id: string; title: string; file_name: string; file_type: string; file_size_bytes: number; uploaded_by?: string }
interface Attempt { id: string; quiz_sets?: { title?: string }; score?: number; total_questions?: number; correct_answers?: number; is_completed?: boolean }

export default function StudentDashboard() {
  const dash = useQuery({ queryKey: ["student", "dashboard"], queryFn: getStudentDashboard, refetchInterval: 30_000 });
  const materialsQuery = useQuery({ queryKey: ["student", "materials"], queryFn: listStudentMaterials });

  const d = dash.data?.data;
  const live: Lecture[] = d?.live_lectures ?? [];
  const upcoming: Lecture[] = d?.upcoming_lectures ?? [];
  const attempts: Attempt[] = d?.recent_quiz_attempts ?? [];
  const materials: Material[] = materialsQuery.data?.data ?? [];
  const attendancePct = d?.attendance?.percentage;

  async function onDownload(m: Material) {
    try { await downloadMaterial(m.id, m.file_name); } catch (e) { toast.error(errorMessage(e)); }
  }

  return (
    <div className="flex flex-col gap-7">
      <PageHeader
        eyebrow={new Date().toLocaleDateString(undefined, { weekday: "long", day: "numeric", month: "long" })}
        title={`Hi, ${d?.profile?.name?.split(" ")[0] ?? "there"}`}
        description={live.length ? "A class is live right now — join in." : upcoming.length ? `Next class: ${upcoming[0].title} at ${fmtTime(upcoming[0].scheduled_time)}.` : "No classes scheduled yet."}
      />

      {live.map((lec) => (
        <div key={lec.id} className="flex flex-wrap items-center gap-4 rounded-xl bg-live p-5 text-white">
          <span className="inline-flex size-11 items-center justify-center rounded-full bg-white/15"><Radio className="size-5" /></span>
          <div className="min-w-0 flex-1">
            <div className="text-[11px] font-bold tracking-[0.08em]">LIVE NOW</div>
            <div className="truncate font-heading text-lg font-semibold">{lec.title}</div>
            <div className="text-sm text-white/80">{lec.teacher_name || "Your teacher"} · started {fmtTime(lec.scheduled_time)}</div>
          </div>
          <Button size="lg" className="bg-white text-live hover:bg-white/90" nativeButton={false} render={<Link href={`/student/session/${lec.id}`} />}>
            Join class
          </Button>
        </div>
      ))}

      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard label="My cohorts" value={d?.counts?.cohorts ?? 0} loading={dash.isLoading} />
        <StatCard label="Attendance" value={attendancePct != null ? `${attendancePct}%` : "—"} tone="ink" hint={d?.attendance ? `${d.attendance.present_classes} of ${d.attendance.total_classes} classes` : undefined} loading={dash.isLoading} />
        <StatCard label="Quizzes taken" value={d?.counts?.quizzes_taken ?? 0} loading={dash.isLoading} />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <section className="panel overflow-hidden">
          <div className="panel-head"><h2 className="text-base font-semibold">Upcoming classes</h2></div>
          <QueryState isLoading={dash.isLoading} isError={dash.isError} error={dash.error} refetch={dash.refetch} isEmpty={upcoming.length === 0} emptyTitle="Nothing scheduled" emptyHint="Your teacher hasn't scheduled the next class yet." rows={2}>
            <ul className="divide-y divide-border">
              {upcoming.map((lec) => (
                <li key={lec.id} className="flex items-center gap-3 px-5 py-3.5">
                  <DateChip iso={lec.scheduled_time} />
                  <div className="min-w-0 flex-1">
                    <div className="truncate font-semibold">{lec.title}</div>
                    <div className="text-[13px] text-muted-foreground">{fmtTime(lec.scheduled_time)} · {lec.duration_minutes ?? 60} min{lec.teacher_name ? ` · ${lec.teacher_name}` : ""}</div>
                  </div>
                  <StatusBadge status="scheduled" />
                </li>
              ))}
            </ul>
          </QueryState>
        </section>

        <section className="panel overflow-hidden">
          <div className="panel-head"><h2 className="text-base font-semibold">Materials</h2></div>
          <QueryState isLoading={materialsQuery.isLoading} isError={materialsQuery.isError} error={materialsQuery.error} refetch={materialsQuery.refetch} isEmpty={materials.length === 0} emptyTitle="No materials yet" rows={2}>
            <ul className="divide-y divide-border">
              {materials.slice(0, 6).map((m) => (
                <li key={m.id} className="flex items-center gap-3 px-5 py-3">
                  <span className="inline-flex size-9 shrink-0 items-center justify-center rounded-[10px] bg-ink-soft text-ink"><FileText className="size-4" /></span>
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-semibold">{m.title}</div>
                    <div className="text-xs text-muted-foreground">{m.file_type.toUpperCase()}{m.uploaded_by ? ` · ${m.uploaded_by}` : ""}</div>
                  </div>
                  <Button size="sm" variant="outline" onClick={() => onDownload(m)}><Download data-icon="inline-start" /> Download</Button>
                </li>
              ))}
            </ul>
          </QueryState>
        </section>

        <section className="panel overflow-hidden lg:col-span-2">
          <div className="panel-head">
            <h2 className="text-base font-semibold">Recent quiz results</h2>
            <Link href="/dashboard/student/quizzes" className="text-sm font-semibold text-ink hover:underline">All results</Link>
          </div>
          <QueryState isLoading={dash.isLoading} isError={dash.isError} error={dash.error} refetch={dash.refetch} isEmpty={attempts.length === 0} emptyTitle="No quiz attempts yet" emptyHint="Quizzes are taken in the Digi-Kul mobile app." rows={2}>
            <ul className="divide-y divide-border">
              {attempts.map((a) => {
                const total = a.total_questions ?? 0;
                const pct = total ? Math.round(((a.correct_answers ?? 0) / total) * 100) : null;
                return (
                  <li key={a.id} className="flex items-center gap-3 px-5 py-3.5">
                    <div className="min-w-0 flex-1">
                      <div className="truncate font-semibold">{a.quiz_sets?.title ?? "Quiz"}</div>
                      <div className="text-[13px] text-muted-foreground">{a.is_completed ? `${a.correct_answers ?? 0}/${total} correct` : "In progress"}</div>
                    </div>
                    {pct != null && <span className={`font-heading text-lg font-bold ${pct >= 70 ? "text-online" : pct >= 40 ? "text-saffron-ink" : "text-live"}`}>{pct}%</span>}
                  </li>
                );
              })}
            </ul>
          </QueryState>
        </section>
      </div>
    </div>
  );
}
