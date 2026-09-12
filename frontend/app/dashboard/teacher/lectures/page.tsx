"use client";

import { Suspense, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Play, Square, Mic, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { PageHeader } from "@/components/app/PageHeader";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState, errorMessage } from "@/components/app/QueryState";
import { DateChip, fmtDateTime, fmtTime } from "@/components/app/DateChip";
import { listLectures, listCohorts, createLecture, startLecture, endLecture, deleteLecture } from "@/lib/api";

interface Lecture {
  id: string;
  title: string;
  cohort_id: string;
  scheduled_time: string;
  duration?: number;
  status: string;
}

export default function TeacherLecturesPage() {
  return (
    <Suspense fallback={null}>
      <LecturesInner />
    </Suspense>
  );
}

function LecturesInner() {
  const router = useRouter();
  const search = useSearchParams();
  const queryClient = useQueryClient();
  // `?new=1` (from the dashboard CTA) opens the dialog on first render.
  const [open, setOpen] = useState(() => search.get("new") === "1");
  const [formError, setFormError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    cohort_id: "",
    title: "",
    description: "",
    scheduled_time: "",
    duration: 60,
  });

  const lecturesQuery = useQuery({ queryKey: ["teacher", "lectures"], queryFn: listLectures });
  const cohortsQuery = useQuery({ queryKey: ["teacher", "cohorts"], queryFn: listCohorts });

  const lectures: Lecture[] = lecturesQuery.data?.data ?? [];
  const cohorts: { id: string; name: string }[] = cohortsQuery.data?.data ?? [];
  const cohortName = (id: string) => cohorts.find((c) => c.id === id)?.name ?? "Cohort";
  const invalidate = () => queryClient.invalidateQueries({ queryKey: ["teacher", "lectures"] });

  const createMutation = useMutation({
    mutationFn: createLecture,
    onSuccess: () => {
      invalidate();
      setOpen(false);
      setFormData({ cohort_id: "", title: "", description: "", scheduled_time: "", duration: 60 });
      setFormError(null);
      toast.success("Lecture scheduled");
    },
    onError: (err) => setFormError(errorMessage(err)),
  });

  const startMutation = useMutation({
    mutationFn: startLecture,
    onSuccess: (_d, id) => {
      invalidate();
      toast.success("You're live — opening the room");
      router.push(`/teacher/session/${id}`);
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  const endMutation = useMutation({
    mutationFn: endLecture,
    onSuccess: () => {
      invalidate();
      toast.success("Lecture ended");
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteLecture,
    onSuccess: () => {
      invalidate();
      toast.success("Lecture cancelled");
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    setFormError(null);
    if (!formData.cohort_id || !formData.title || !formData.scheduled_time) {
      setFormError("Cohort, title, and scheduled time are required");
      return;
    }
    createMutation.mutate({ ...formData, scheduled_time: new Date(formData.scheduled_time).toISOString() });
  }

  const live = lectures.filter((l) => l.status === "live");
  const scheduled = lectures.filter((l) => l.status === "scheduled").sort((a, b) => a.scheduled_time.localeCompare(b.scheduled_time));
  const ended = lectures.filter((l) => l.status === "ended" || l.status === "cancelled");
  const busy = startMutation.isPending || endMutation.isPending || deleteMutation.isPending;

  return (
    <div className="flex flex-col gap-7">
      <PageHeader
        title="Lectures"
        description="Schedule classes and open live rooms."
        actions={
          <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger
              render={
                <Button>
                  <Plus data-icon="inline-start" /> Schedule lecture
                </Button>
              }
            />
            <DialogContent className="sm:max-w-[440px]">
              <DialogHeader>
                <DialogTitle>Schedule a lecture</DialogTitle>
                <DialogDescription>Students in the cohort will see it as upcoming.</DialogDescription>
              </DialogHeader>
              <form onSubmit={handleCreate} className="flex flex-col gap-4 pt-2" noValidate>
                <div className="flex flex-col gap-2">
                  <Label htmlFor="lecture-cohort">Cohort *</Label>
                  <Select value={formData.cohort_id} onValueChange={(val) => setFormData({ ...formData, cohort_id: val ?? "" })}>
                    <SelectTrigger id="lecture-cohort" className="w-full">
                      <SelectValue placeholder={cohorts.length ? "Select a cohort" : "No cohorts yet"} />
                    </SelectTrigger>
                    <SelectContent>
                      {cohorts.map((c) => (
                        <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex flex-col gap-2">
                  <Label htmlFor="lecture-title">Title *</Label>
                  <Input id="lecture-title" placeholder="e.g. Introduction to Physics" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} required />
                </div>
                <div className="flex flex-col gap-2">
                  <Label htmlFor="lecture-desc">Description</Label>
                  <Textarea id="lecture-desc" placeholder="Topic overview…" value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} className="resize-none" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-2">
                    <Label htmlFor="lecture-time">When *</Label>
                    <Input id="lecture-time" type="datetime-local" value={formData.scheduled_time} onChange={(e) => setFormData({ ...formData, scheduled_time: e.target.value })} required />
                  </div>
                  <div className="flex flex-col gap-2">
                    <Label htmlFor="lecture-duration">Duration (min)</Label>
                    <Input id="lecture-duration" type="number" min={10} max={300} value={formData.duration} onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value) || 60 })} />
                  </div>
                </div>
                {formError && <p role="alert" className="rounded-lg bg-live-soft px-3 py-2 text-sm font-medium text-live">{formError}</p>}
                <DialogFooter>
                  <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
                  <Button type="submit" disabled={createMutation.isPending}>
                    {createMutation.isPending ? "Scheduling…" : "Schedule"}
                  </Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        }
      />

      {live.length > 0 && (
        <section className="panel overflow-hidden border-live/25">
          <div className="panel-head">
            <h2 className="flex items-center gap-2 text-base font-semibold text-live"><span className="live-dot" /> Live now</h2>
          </div>
          <ul className="divide-y divide-border">
            {live.map((lec) => (
              <li key={lec.id} className="flex flex-wrap items-center gap-3 px-5 py-4">
                <span className="inline-flex size-10 shrink-0 items-center justify-center rounded-[10px] bg-live-soft text-live"><Mic className="size-5" /></span>
                <div className="min-w-0 flex-1">
                  <div className="truncate font-semibold">{lec.title}</div>
                  <div className="text-[13px] text-muted-foreground">{cohortName(lec.cohort_id)}</div>
                </div>
                <Button size="sm" nativeButton={false} render={<Link href={`/teacher/session/${lec.id}`} />}>Open room</Button>
                <Button size="sm" variant="destructive" onClick={() => { if (confirm("End this lecture for everyone?")) endMutation.mutate(lec.id); }} disabled={busy}>
                  <Square data-icon="inline-start" /> End
                </Button>
              </li>
            ))}
          </ul>
        </section>
      )}

      <section className="panel overflow-hidden">
        <div className="panel-head"><h2 className="text-base font-semibold">Scheduled</h2></div>
        <QueryState
          isLoading={lecturesQuery.isLoading}
          isError={lecturesQuery.isError}
          error={lecturesQuery.error}
          refetch={lecturesQuery.refetch}
          isEmpty={scheduled.length === 0}
          emptyTitle="No upcoming lectures"
          emptyHint="Schedule one to make it appear on students' dashboards."
        >
          <ul className="divide-y divide-border">
            {scheduled.map((lec) => (
              <li key={lec.id} className="flex flex-wrap items-center gap-3 px-5 py-3.5">
                <DateChip iso={lec.scheduled_time} />
                <div className="min-w-0 flex-1">
                  <div className="truncate font-semibold">{lec.title}</div>
                  <div className="text-[13px] text-muted-foreground">{fmtTime(lec.scheduled_time)} · {lec.duration ?? 60} min · {cohortName(lec.cohort_id)}</div>
                </div>
                <StatusBadge status="scheduled" />
                <Button size="sm" onClick={() => startMutation.mutate(lec.id)} disabled={busy}>
                  <Play data-icon="inline-start" /> Go live
                </Button>
                <Button size="icon-sm" variant="ghost" aria-label="Cancel lecture" title="Cancel lecture" onClick={() => { if (confirm(`Cancel "${lec.title}"?`)) deleteMutation.mutate(lec.id); }} disabled={busy}>
                  <Trash2 />
                </Button>
              </li>
            ))}
          </ul>
        </QueryState>
      </section>

      {ended.length > 0 && (
        <section className="panel overflow-hidden">
          <div className="panel-head"><h2 className="text-base font-semibold">Past lectures</h2></div>
          <ul className="divide-y divide-border">
            {ended.slice(0, 10).map((lec) => (
              <li key={lec.id} className="flex flex-wrap items-center gap-3 px-5 py-3.5 text-muted-foreground">
                <div className="min-w-0 flex-1">
                  <div className="truncate font-semibold text-foreground">{lec.title}</div>
                  <div className="text-[13px]">{fmtDateTime(lec.scheduled_time)} · {cohortName(lec.cohort_id)}</div>
                </div>
                <StatusBadge status={lec.status} />
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
