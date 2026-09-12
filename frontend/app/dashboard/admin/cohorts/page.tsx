"use client";

import { useQuery } from "@tanstack/react-query";
import { Users } from "lucide-react";
import { listCohorts } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState } from "@/components/app/QueryState";
import { CreateCohortDialog } from "@/components/CreateCohortDialog";

interface Cohort { id: string; name: string; enrollment_code: string; max_students: number; academic_year: string | null; is_active: boolean; description?: string | null }

export default function AdminCohortsPage() {
  const query = useQuery({ queryKey: ["admin", "cohorts"], queryFn: listCohorts });
  const cohorts: Cohort[] = query.data?.data ?? [];
  return (
    <div className="flex flex-col gap-7">
      <PageHeader title="Cohorts" description="All cohorts in your institution." actions={<CreateCohortDialog />} />
      <QueryState isLoading={query.isLoading} isError={query.isError} error={query.error} refetch={query.refetch} isEmpty={cohorts.length === 0} emptyTitle="No cohorts yet">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {cohorts.map((c) => (
            <div key={c.id} className="panel flex flex-col gap-3 p-5">
              <div className="flex items-start justify-between gap-3">
                <span className="inline-flex size-10 items-center justify-center rounded-[10px] bg-ink-soft text-ink"><Users className="size-5" /></span>
                <StatusBadge status={c.is_active ? "active" : "inactive"} />
              </div>
              <div className="font-heading text-base font-semibold">{c.name}</div>
              {c.description && <p className="line-clamp-2 text-sm text-muted-foreground">{c.description}</p>}
              <div className="mt-auto flex items-center justify-between text-xs text-muted-foreground">
                <span>Code <span className="font-mono font-semibold text-foreground">{c.enrollment_code}</span></span>
                <span>Max {c.max_students}{c.academic_year ? ` · ${c.academic_year}` : ""}</span>
              </div>
            </div>
          ))}
        </div>
      </QueryState>
    </div>
  );
}
