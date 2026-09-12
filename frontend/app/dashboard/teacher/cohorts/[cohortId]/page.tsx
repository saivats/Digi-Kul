"use client";

import { useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Download, FileText, Trash2, Upload } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/app/PageHeader";
import { StatCard } from "@/components/app/StatCard";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState, errorMessage } from "@/components/app/QueryState";
import { fmtDateTime } from "@/components/app/DateChip";
import {
  getCohort,
  getCohortStudents,
  listLecturesByCohort,
  listCohortMaterials,
  uploadMaterial,
  deleteMaterial,
  downloadMaterial,
} from "@/lib/api";

interface Material {
  id: string;
  title: string;
  file_name: string;
  file_type: string;
  file_size_bytes: number;
  uploaded_at: string;
  download_count?: number;
}

function fmtSize(bytes: number) {
  if (!bytes) return "—";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export default function CohortDetailPage() {
  const { cohortId } = useParams<{ cohortId: string }>();
  const qc = useQueryClient();
  const fileRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);

  const cohortQuery = useQuery({ queryKey: ["cohort", cohortId], queryFn: () => getCohort(cohortId), enabled: !!cohortId });
  const studentsQuery = useQuery({ queryKey: ["cohort-students", cohortId], queryFn: () => getCohortStudents(cohortId), enabled: !!cohortId });
  const lecturesQuery = useQuery({ queryKey: ["cohort-lectures", cohortId], queryFn: () => listLecturesByCohort(cohortId), enabled: !!cohortId });
  const materialsQuery = useQuery({ queryKey: ["cohort-materials", cohortId], queryFn: () => listCohortMaterials(cohortId), enabled: !!cohortId });

  const deleteMut = useMutation({
    mutationFn: deleteMaterial,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["cohort-materials", cohortId] }); toast.success("Material removed"); },
    onError: (e) => toast.error(errorMessage(e)),
  });

  async function onFilePicked(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (file.size > 50 * 1024 * 1024) { toast.error("Files must be under 50 MB"); return; }
    setUploading(true);
    try {
      const form = new FormData();
      form.append("file", file);
      await uploadMaterial(form, { cohort_id: cohortId, title: file.name });
      qc.invalidateQueries({ queryKey: ["cohort-materials", cohortId] });
      toast.success(`Uploaded ${file.name}`);
    } catch (err) {
      toast.error(errorMessage(err));
    } finally {
      setUploading(false);
    }
  }

  async function onDownload(m: Material) {
    try { await downloadMaterial(m.id, m.file_name); } catch (err) { toast.error(errorMessage(err)); }
  }

  const cohort = cohortQuery.data?.data;
  const students: { id: string; name?: string; email?: string }[] = studentsQuery.data?.data ?? [];
  const lectures: { id: string; title: string; scheduled_time: string; status: string }[] = lecturesQuery.data?.data ?? [];
  const materials: Material[] = materialsQuery.data?.data ?? [];

  if (cohortQuery.isLoading) return <div className="h-40 animate-pulse rounded-xl bg-muted" />;
  if (cohortQuery.isError || !cohort) {
    return (
      <div className="panel p-8 text-center">
        <div className="font-semibold">Cohort not found</div>
        <Button variant="outline" size="sm" className="mt-3" nativeButton={false} render={<Link href="/dashboard/teacher/cohorts" />}>
          <ArrowLeft data-icon="inline-start" /> Back to cohorts
        </Button>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-7">
      <div className="flex items-start gap-3">
        <Button variant="outline" size="icon" aria-label="Back to cohorts" nativeButton={false} render={<Link href="/dashboard/teacher/cohorts" />}>
          <ArrowLeft />
        </Button>
        <PageHeader
          eyebrow={cohort.academic_year ? `Academic year ${cohort.academic_year}` : "Cohort"}
          title={cohort.name}
          description={`Enrollment code ${cohort.enrollment_code}${cohort.description ? ` · ${cohort.description}` : ""}`}
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <div className="panel flex flex-col gap-2.5 p-5">
          <div className="text-[13px] font-medium text-muted-foreground">Status</div>
          <StatusBadge status={cohort.is_active ? "active" : "inactive"} className="w-fit" />
        </div>
        <StatCard label="Students" value={students.length} hint={cohort.max_students ? `of ${cohort.max_students} max` : "no cap"} loading={studentsQuery.isLoading} />
        <StatCard label="Lectures" value={lectures.length} loading={lecturesQuery.isLoading} />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <section className="panel overflow-hidden">
          <div className="panel-head">
            <h2 className="text-base font-semibold">Materials</h2>
            <input ref={fileRef} type="file" className="hidden" onChange={onFilePicked} accept=".pdf,.doc,.docx,.ppt,.pptx,.xls,.xlsx,.txt,.jpg,.jpeg,.png,.gif,.webp,.mp3,.wav,.ogg,.m4a" />
            <Button size="sm" onClick={() => fileRef.current?.click()} disabled={uploading}>
              <Upload data-icon="inline-start" /> {uploading ? "Uploading…" : "Upload"}
            </Button>
          </div>
          <QueryState isLoading={materialsQuery.isLoading} isError={materialsQuery.isError} error={materialsQuery.error} refetch={materialsQuery.refetch} isEmpty={materials.length === 0} emptyTitle="No materials yet" emptyHint="Upload notes, slides or audio for students to download — they can save them offline in the app." rows={2}>
            <ul className="divide-y divide-border">
              {materials.map((m) => (
                <li key={m.id} className="flex items-center gap-3 px-5 py-3">
                  <span className="inline-flex size-9 shrink-0 items-center justify-center rounded-[10px] bg-ink-soft text-ink"><FileText className="size-4" /></span>
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-semibold">{m.title}</div>
                    <div className="text-xs text-muted-foreground">{m.file_type.toUpperCase()} · {fmtSize(m.file_size_bytes)} · {fmtDateTime(m.uploaded_at)}</div>
                  </div>
                  <Button size="icon-sm" variant="ghost" aria-label="Download" title="Download" onClick={() => onDownload(m)}><Download /></Button>
                  <Button size="icon-sm" variant="ghost" aria-label="Delete" title="Delete" onClick={() => { if (confirm(`Delete "${m.title}"?`)) deleteMut.mutate(m.id); }} disabled={deleteMut.isPending}><Trash2 /></Button>
                </li>
              ))}
            </ul>
          </QueryState>
        </section>

        <section className="panel overflow-hidden">
          <div className="panel-head"><h2 className="text-base font-semibold">Enrolled students</h2></div>
          <QueryState isLoading={studentsQuery.isLoading} isError={studentsQuery.isError} error={studentsQuery.error} refetch={studentsQuery.refetch} isEmpty={students.length === 0} emptyTitle="No students yet" emptyHint={`Students join with the code ${cohort.enrollment_code}.`} rows={2}>
            <ul className="divide-y divide-border">
              {students.map((s) => (
                <li key={s.id} className="flex items-center gap-3 px-5 py-3">
                  <span className="inline-flex size-8 items-center justify-center rounded-full bg-muted text-xs font-bold">{(s.name || "?").charAt(0).toUpperCase()}</span>
                  <div className="min-w-0">
                    <div className="truncate text-sm font-semibold">{s.name || "Unknown student"}</div>
                    <div className="truncate text-xs text-muted-foreground">{s.email}</div>
                  </div>
                </li>
              ))}
            </ul>
          </QueryState>
        </section>

        <section className="panel overflow-hidden lg:col-span-2">
          <div className="panel-head">
            <h2 className="text-base font-semibold">Lectures</h2>
            <Link href="/dashboard/teacher/lectures" className="text-sm font-semibold text-ink hover:underline">Manage</Link>
          </div>
          <QueryState isLoading={lecturesQuery.isLoading} isError={lecturesQuery.isError} error={lecturesQuery.error} refetch={lecturesQuery.refetch} isEmpty={lectures.length === 0} emptyTitle="No lectures scheduled" rows={2}>
            <ul className="divide-y divide-border">
              {lectures.map((lecture) => (
                <li key={lecture.id} className="flex items-center gap-3 px-5 py-3">
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-semibold">{lecture.title}</div>
                    <div className="text-xs text-muted-foreground">{fmtDateTime(lecture.scheduled_time)}</div>
                  </div>
                  <StatusBadge status={lecture.status} />
                  {lecture.status === "live" && <Button size="sm" nativeButton={false} render={<Link href={`/teacher/session/${lecture.id}`} />}>Open room</Button>}
                </li>
              ))}
            </ul>
          </QueryState>
        </section>
      </div>
    </div>
  );
}
