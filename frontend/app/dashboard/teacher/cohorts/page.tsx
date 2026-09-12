"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ChevronRight, Users } from "lucide-react";
import { listCohorts } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState } from "@/components/app/QueryState";
import { CreateCohortDialog } from "@/components/CreateCohortDialog";

interface Cohort {
  id: string;
  name: string;
  description: string | null;
  enrollment_code: string;
  academic_year: string | null;
  is_active: boolean;
}

export default function TeacherCohortsPage() {
  const cohortsQuery = useQuery({ queryKey: ["teacher", "cohorts"], queryFn: listCohorts });
  const cohorts: Cohort[] = cohortsQuery.data?.data ?? [];

  return (
    <div className="flex flex-col gap-7">
      <PageHeader title="My cohorts" description="Your classes and the students in them." actions={<CreateCohortDialog />} />
      <QueryState
        isLoading={cohortsQuery.isLoading}
        isError={cohortsQuery.isError}
        error={cohortsQuery.error}
        refetch={cohortsQuery.refetch}
        isEmpty={cohorts.length === 0}
        emptyTitle="No cohorts yet"
        emptyHint="Create one and share its enrollment code with students."
      >
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {cohorts.map((cohort) => (
            <Link key={cohort.id} href={`/dashboard/teacher/cohorts/${cohort.id}`} className="panel group flex flex-col gap-3 p-5 transition-colors hover:border-ink/40">
              <div className="flex items-start justify-between gap-3">
                <span className="inline-flex size-10 items-center justify-center rounded-[10px] bg-ink-soft text-ink"><Users className="size-5" /></span>
                <StatusBadge status={cohort.is_active ? "active" : "inactive"} />
              </div>
              <div>
                <div className="flex items-center gap-1 font-heading text-base font-semibold">
                  {cohort.name}
                  <ChevronRight className="size-4 text-muted-foreground transition-transform group-hover:translate-x-0.5" />
                </div>
                {cohort.description && <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{cohort.description}</p>}
              </div>
              <div className="mt-auto flex items-center justify-between text-xs text-muted-foreground">
                <span>Code <span className="font-mono font-semibold text-foreground">{cohort.enrollment_code}</span></span>
                {cohort.academic_year && <span>{cohort.academic_year}</span>}
              </div>
            </Link>
          ))}
        </div>
      </QueryState>
    </div>
  );
}
