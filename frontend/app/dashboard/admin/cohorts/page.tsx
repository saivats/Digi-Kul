"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { listCohorts } from "@/lib/api";

export default function AdminCohortsPage() {
  const query = useQuery({
    queryKey: ["admin", "cohorts"],
    queryFn: listCohorts,
  });

  const cohorts = query.data?.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Cohorts</h1>
        <p className="text-muted-foreground mt-1">
          All cohorts in your institution.
        </p>
      </div>

      {cohorts.length === 0 ? (
        <Card className="border-border/50">
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">No cohorts found.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {cohorts.map(
            (c: {
              id: string;
              name: string;
              enrollment_code: string;
              max_students: number;
              academic_year: string | null;
              is_active: boolean;
            }) => (
              <Card key={c.id} className="border-border/50">
                <CardContent className="pt-6 space-y-2">
                  <div className="flex items-center justify-between">
                    <p className="font-semibold">{c.name}</p>
                    <Badge variant={c.is_active ? "default" : "secondary"}>
                      {c.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Code:{" "}
                    <span className="font-mono text-foreground">
                      {c.enrollment_code}
                    </span>
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Max students: {c.max_students}
                  </p>
                  {c.academic_year && (
                    <p className="text-xs text-muted-foreground">
                      Year: {c.academic_year}
                    </p>
                  )}
                </CardContent>
              </Card>
            )
          )}
        </div>
      )}
    </div>
  );
}
