"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Mic, Play, Plus } from "lucide-react";
import { toast } from "sonner";
import { getTeacherProfile, listLectures, listCohorts, startLecture } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { StatCard } from "@/components/app/StatCard";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState, errorMessage } from "@/components/app/QueryState";
import { DateChip, fmtTime } from "@/components/app/DateChip";
import { Button } from "@/components/ui/button";

interface Lecture {
  id: string;
  title: string;
  cohort_id: string;
  scheduled_time: string;
  duration?: number;
  status: string;
}

function greeting() {
  const h = new Date().getHours();
  return h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
}

export default function TeacherDashboard() {
  const router = useRouter();
  const qc = useQueryClient();
  const profileQuery = useQuery({ queryKey: ["teacher", "profile"], queryFn: getTeacherProfile });
  const lecturesQuery = useQuery({ queryKey: ["teacher", "lectures"], queryFn: listLectures });
  const cohortsQuery = useQuery({ queryKey: ["teacher", "cohorts"], queryFn: listCohorts });

  const profile = profileQuery.data?.data;
  const lectures: Lecture[] = lecturesQuery.data?.data ?? [];
  const cohorts = cohortsQuery.data?.data ?? [];
  const cohortName = (id: string) =>
    cohorts.find((c: { id: string; name: string }) => c.id === id)?.name ?? "Cohort";
  const live = lectures.filter((l) => l.status === "live");
  const scheduled = lectures
    .filter((l) => l.status === "scheduled")
    .sort((a, b) => a.scheduled_time.localeCompare(b.scheduled_time));

  const startMutation = useMutation({
    mutationFn: startLecture,
    onSuccess: (_d, id) => {
      qc.invalidateQueries({ queryKey: ["teacher", "lectures"] });
      toast.success("You're live — opening the room");
      router.push(`/teacher/session/${id}`);
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  const today = new Date().toLocaleDateString(undefined, { weekday: "long", day: "numeric", month: "long" });

  return (
    <div className="flex flex-col gap-7">
      <PageHeader
        eyebrow={today}
        title={`${greeting()}, ${profile?.name ?? "Teacher"}`}
        description={
          live.length > 0
            ? `${live.length} class${live.length > 1 ? "es are" : " is"} live right now.`
            : scheduled.length > 0
              ? `Next up: ${scheduled[0].title} at ${fmtTime(scheduled[0].scheduled_time)}.`
              : "Nothing scheduled yet — plan your next class."
        }
        actions={
          <Button nativeButton={false} render={<Link href="/dashboard/teacher/lectures?new=1" />}>
            <Plus data-icon="inline-start" /> Schedule lecture
          </Button>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="My cohorts" value={cohorts.length} loading={cohortsQuery.isLoading} />
        <StatCard label="Total lectures" value={lectures.length} loading={lecturesQuery.isLoading} />
        <StatCard label="Live now" value={live.length} tone={live.length ? "live" : "default"} loading={lecturesQuery.isLoading} />
        <StatCard label="Scheduled" value={scheduled.length} loading={lecturesQuery.isLoading} />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <section className="panel overflow-hidden">
          <div className="panel-head">
            <h2 className="text-base font-semibold">Live sessions</h2>
            <Link href="/dashboard/teacher/lectures" className="text-sm font-semibold text-ink hover:underline">
              All lectures
            </Link>
          </div>
          <QueryState
            isLoading={lecturesQuery.isLoading}
            isError={lecturesQuery.isError}
            error={lecturesQuery.error}
            refetch={lecturesQuery.refetch}
            isEmpty={live.length === 0}
            emptyTitle="No live sessions"
            emptyHint="Start a scheduled lecture and the room opens here."
            rows={1}
          >
            <ul className="divide-y divide-border">
              {live.map((lec) => (
                <li key={lec.id} className="flex flex-wrap items-center gap-3 px-5 py-4">
                  <span className="inline-flex size-10 shrink-0 items-center justify-center rounded-[10px] bg-live-soft text-live">
                    <Mic className="size-5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <div className="truncate font-semibold">{lec.title}</div>
                    <div className="text-[13px] text-muted-foreground">{cohortName(lec.cohort_id)}</div>
                  </div>
                  <StatusBadge status="live" />
                  <Button size="sm" nativeButton={false} render={<Link href={`/teacher/session/${lec.id}`} />}>
                    Open room
                  </Button>
                </li>
              ))}
            </ul>
          </QueryState>
        </section>

        <section className="panel overflow-hidden">
          <div className="panel-head">
            <h2 className="text-base font-semibold">Upcoming</h2>
          </div>
          <QueryState
            isLoading={lecturesQuery.isLoading}
            isError={lecturesQuery.isError}
            error={lecturesQuery.error}
            refetch={lecturesQuery.refetch}
            isEmpty={scheduled.length === 0}
            emptyTitle="No upcoming lectures"
            emptyAction={
              <Button variant="outline" size="sm" nativeButton={false} render={<Link href="/dashboard/teacher/lectures?new=1" />}>
                <Plus data-icon="inline-start" /> Schedule one
              </Button>
            }
            rows={2}
          >
            <ul className="divide-y divide-border">
              {scheduled.slice(0, 5).map((lec) => (
                <li key={lec.id} className="flex flex-wrap items-center gap-3 px-5 py-3.5">
                  <DateChip iso={lec.scheduled_time} />
                  <div className="min-w-0 flex-1">
                    <div className="truncate font-semibold">{lec.title}</div>
                    <div className="text-[13px] text-muted-foreground">
                      {fmtTime(lec.scheduled_time)} · {lec.duration ?? 60} min · {cohortName(lec.cohort_id)}
                    </div>
                  </div>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => startMutation.mutate(lec.id)}
                    disabled={startMutation.isPending}
                  >
                    <Play data-icon="inline-start" /> Go live
                  </Button>
                </li>
              ))}
            </ul>
          </QueryState>
        </section>
      </div>
    </div>
  );
}
