"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Building2 } from "lucide-react";
import { getPlatformStats, getInstitutionStats, listInstitutions } from "@/lib/api";
import { getUser } from "@/lib/auth";
import { PageHeader } from "@/components/app/PageHeader";
import { StatCard } from "@/components/app/StatCard";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState } from "@/components/app/QueryState";
import { useMemo } from "react";

export default function AdminDashboard() {
  const user = useMemo(() => getUser(), []);
  const isSuperAdmin = user?.user_type === "super_admin" || user?.user_type === "admin";
  const isInstAdmin = user?.user_type === "institution_admin";
  const instId = user?.institution_id;

  const statsQuery = useQuery({ queryKey: ["admin", "platform-stats"], queryFn: getPlatformStats, enabled: isSuperAdmin });
  const instStatsQuery = useQuery({ queryKey: ["admin", "inst-stats", instId], queryFn: () => getInstitutionStats(instId!), enabled: isInstAdmin && !!instId });
  const institutionsQuery = useQuery({ queryKey: ["admin", "institutions"], queryFn: listInstitutions, enabled: isSuperAdmin });

  const activeQuery = isSuperAdmin ? statsQuery : instStatsQuery;
  const stats = activeQuery.data?.data;
  const institutions = institutionsQuery.data?.data ?? [];

  return (
    <div className="flex flex-col gap-7">
      <PageHeader
        eyebrow={isSuperAdmin ? "Platform" : "Institution"}
        title={isSuperAdmin ? "Platform overview" : "Institution overview"}
        description={isSuperAdmin ? "Every institution, teacher and student on Digi-Kul." : "People and classes in your institution."}
      />

      <div className={`grid gap-4 sm:grid-cols-2 ${isSuperAdmin ? "lg:grid-cols-5" : "lg:grid-cols-4"}`}>
        {isSuperAdmin && <StatCard label="Institutions" value={stats?.total_institutions ?? 0} loading={activeQuery.isLoading} />}
        <StatCard label="Teachers" value={stats?.total_teachers ?? 0} loading={activeQuery.isLoading} />
        <StatCard label="Students" value={stats?.total_students ?? 0} loading={activeQuery.isLoading} />
        <StatCard label="Cohorts" value={stats?.total_cohorts ?? 0} loading={activeQuery.isLoading} />
        <StatCard label="Lectures" value={stats?.total_lectures ?? 0} loading={activeQuery.isLoading} />
      </div>

      {isSuperAdmin && (
        <section className="panel overflow-hidden">
          <div className="panel-head">
            <h2 className="text-base font-semibold">Institutions</h2>
            <Link href="/dashboard/admin/institutions" className="text-sm font-semibold text-ink hover:underline">Manage</Link>
          </div>
          <QueryState isLoading={institutionsQuery.isLoading} isError={institutionsQuery.isError} error={institutionsQuery.error} refetch={institutionsQuery.refetch} isEmpty={institutions.length === 0} emptyTitle="No institutions registered">
            <ul className="divide-y divide-border">
              {institutions.map((inst: { id: string; name: string; domain: string; is_active: boolean; contact_email: string | null }) => (
                <li key={inst.id} className="flex items-center gap-3 px-5 py-3.5">
                  <span className="inline-flex size-10 items-center justify-center rounded-[10px] bg-ink-soft text-ink"><Building2 className="size-5" /></span>
                  <div className="min-w-0 flex-1">
                    <div className="truncate font-semibold">{inst.name}</div>
                    <div className="truncate text-[13px] text-muted-foreground">{inst.domain}{inst.contact_email && ` · ${inst.contact_email}`}</div>
                  </div>
                  <StatusBadge status={inst.is_active ? "active" : "inactive"} />
                </li>
              ))}
            </ul>
          </QueryState>
        </section>
      )}
    </div>
  );
}
