"use client";

import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { listCohorts } from "@/lib/api";

export default function TeacherCohortsPage() {
  const cohortsQuery = useQuery({
    queryKey: ["teacher", "cohorts"],
    queryFn: listCohorts,
  });

  const cohorts = cohortsQuery.data?.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">My Cohorts</h1>
        <p className="text-muted-foreground mt-1">
          Manage your assigned cohorts and student groups.
        </p>
      </div>

      {cohorts.length === 0 ? (
        <Card className="border-border/50">
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">
              You are not assigned to any cohorts yet.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {cohorts.map(
            (cohort: {
              id: string;
              name: string;
              description: string | null;
              enrollment_code: string;
              academic_year: string | null;
              is_active: boolean;
            }) => (
              <Link
                key={cohort.id}
                href={`/dashboard/teacher/cohorts/${cohort.id}`}
              >
                <Card className="border-border/50 hover:border-primary/30 transition-colors cursor-pointer h-full">
                  <CardHeader className="pb-2">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-base">{cohort.name}</CardTitle>
                      <Badge variant={cohort.is_active ? "default" : "secondary"}>
                        {cohort.is_active ? "Active" : "Inactive"}
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-1">
                    {cohort.description && (
                      <p className="text-sm text-muted-foreground line-clamp-2">
                        {cohort.description}
                      </p>
                    )}
                    <p className="text-xs text-muted-foreground">
                      Code:{" "}
                      <span className="font-mono text-foreground">
                        {cohort.enrollment_code}
                      </span>
                    </p>
                    {cohort.academic_year && (
                      <p className="text-xs text-muted-foreground">
                        Year: {cohort.academic_year}
                      </p>
                    )}
                  </CardContent>
                </Card>
              </Link>
            )
          )}
        </div>
      )}
    </div>
  );
}
