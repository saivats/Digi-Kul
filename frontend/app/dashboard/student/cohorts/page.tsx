"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Users } from "lucide-react";
import { listStudentCohorts, joinCohortByCode } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState, errorMessage } from "@/components/app/QueryState";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

interface Cohort { id: string; name: string; description: string | null; is_active: boolean; academic_year?: string | null }

export default function StudentCohortsPage() {
  const qc = useQueryClient();
  const [code, setCode] = useState("");
  const query = useQuery({ queryKey: ["student", "cohorts"], queryFn: listStudentCohorts });
  const cohorts: Cohort[] = query.data?.data ?? [];

  const joinMut = useMutation({
    mutationFn: joinCohortByCode,
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ["student"] });
      setCode("");
      toast.success(`Joined ${data?.data?.name ?? "cohort"}`);
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  return (
    <div className="flex flex-col gap-7">
      <PageHeader title="My cohorts" description="Classes you are enrolled in." />

      <form
        className="panel flex flex-col gap-3 p-5 sm:flex-row sm:items-end"
        onSubmit={(e) => { e.preventDefault(); if (code.trim()) joinMut.mutate(code.trim()); }}
      >
        <div className="flex flex-1 flex-col gap-2">
          <label htmlFor="join-code" className="text-sm font-medium">Have an enrollment code?</label>
          <Input id="join-code" placeholder="e.g. DEMO2026" value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} className="font-mono" />
        </div>
        <Button type="submit" disabled={!code.trim() || joinMut.isPending}>{joinMut.isPending ? "Joining…" : "Join cohort"}</Button>
      </form>

      <QueryState isLoading={query.isLoading} isError={query.isError} error={query.error} refetch={query.refetch} isEmpty={cohorts.length === 0} emptyTitle="Not enrolled anywhere yet" emptyHint="Ask your teacher for the cohort's enrollment code.">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {cohorts.map((c) => (
            <div key={c.id} className="panel flex flex-col gap-3 p-5">
              <div className="flex items-start justify-between gap-3">
                <span className="inline-flex size-10 items-center justify-center rounded-[10px] bg-ink-soft text-ink"><Users className="size-5" /></span>
                <StatusBadge status={c.is_active ? "active" : "inactive"} />
              </div>
              <div className="font-heading text-base font-semibold">{c.name}</div>
              {c.description && <p className="line-clamp-2 text-sm text-muted-foreground">{c.description}</p>}
              {c.academic_year && <div className="mt-auto text-xs text-muted-foreground">{c.academic_year}</div>}
            </div>
          ))}
        </div>
      </QueryState>
    </div>
  );
}
