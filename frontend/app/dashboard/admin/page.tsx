"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getPlatformStats, getInstitutionStats, listInstitutions } from "@/lib/api";
import { getUser } from "@/lib/auth";

export default function AdminDashboard() {
  const user = getUser();
  const isSuperAdmin =
    user?.user_type === "super_admin" || user?.user_type === "admin";
  const isInstAdmin = user?.user_type === "institution_admin";
  const instId = user?.institution_id;

  const statsQuery = useQuery({
    queryKey: ["admin", "platform-stats"],
    queryFn: getPlatformStats,
    enabled: isSuperAdmin,
  });

  const instStatsQuery = useQuery({
    queryKey: ["admin", "inst-stats", instId],
    queryFn: () => getInstitutionStats(instId!),
    enabled: isInstAdmin && !!instId,
  });

  const institutionsQuery = useQuery({
    queryKey: ["admin", "institutions"],
    queryFn: listInstitutions,
    enabled: isSuperAdmin,
  });

  const stats = isSuperAdmin ? statsQuery.data?.data : instStatsQuery.data?.data;
  const institutions = institutionsQuery.data?.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">
          {isSuperAdmin ? "Platform Dashboard" : "Institution Dashboard"}
        </h1>
        <p className="text-muted-foreground mt-1">
          {isSuperAdmin ? "Platform overview and management." : "Overview of your institution."}
        </p>
      </div>

      {stats && (
        <div className="grid gap-4 md:grid-cols-5">
          {isSuperAdmin && <StatCard title="Institutions" value={stats.total_institutions} />}
          <StatCard title="Teachers" value={stats.total_teachers} />
          <StatCard title="Students" value={stats.total_students} />
          <StatCard title="Cohorts" value={stats.total_cohorts} />
          <StatCard title="Lectures" value={stats.total_lectures} />
        </div>
      )}

      {isSuperAdmin && (
        <Card className="border-border/50">
          <CardHeader>
            <CardTitle className="text-lg">Institutions</CardTitle>
          </CardHeader>
          <CardContent>
            {institutions.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No institutions registered yet.
              </p>
            ) : (
              <div className="space-y-3">
                {institutions.map(
                  (inst: {
                    id: string;
                    name: string;
                    domain: string;
                    is_active: boolean;
                    contact_email: string | null;
                  }) => (
                    <div
                      key={inst.id}
                      className="flex items-center justify-between rounded-lg border border-border/50 p-4"
                    >
                      <div>
                        <p className="font-semibold">{inst.name}</p>
                        <p className="text-sm text-muted-foreground">
                          {inst.domain}
                          {inst.contact_email && ` · ${inst.contact_email}`}
                        </p>
                      </div>
                      <span
                        className={`text-xs font-medium px-2 py-1 rounded-full ${
                          inst.is_active
                            ? "bg-green-500/10 text-green-500"
                            : "bg-red-500/10 text-red-500"
                        }`}
                      >
                        {inst.is_active ? "Active" : "Inactive"}
                      </span>
                    </div>
                  )
                )}
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function StatCard({ title, value }: { title: string; value: number }) {
  return (
    <Card className="border-border/50">
      <CardContent className="pt-6">
        <p className="text-sm text-muted-foreground">{title}</p>
        <p className="text-3xl font-bold mt-1">{value}</p>
      </CardContent>
    </Card>
  );
}
