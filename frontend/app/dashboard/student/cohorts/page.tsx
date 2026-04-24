"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import api from "@/lib/api";

export default function StudentCohortsPage() {
  const query = useQuery({
    queryKey: ["student", "cohorts"],
    queryFn: async () => {
      const { data } = await api.get("/api/students/cohorts");
      return data;
    },
  });

  const cohorts = query.data?.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">My Cohorts</h1>
        <p className="text-muted-foreground mt-1">
          Classes and groups you are enrolled in.
        </p>
      </div>

      {cohorts.length === 0 ? (
        <Card className="border-border/50">
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">
              You are not enrolled in any cohort yet.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {cohorts.map(
            (c: {
              id: string;
              name: string;
              description: string | null;
              is_active: boolean;
            }) => (
              <Card key={c.id} className="border-border/50">
                <CardHeader className="pb-2">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base">{c.name}</CardTitle>
                    <Badge variant={c.is_active ? "default" : "secondary"}>
                      {c.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </div>
                </CardHeader>
                {c.description && (
                  <CardContent>
                    <p className="text-sm text-muted-foreground line-clamp-2">
                      {c.description}
                    </p>
                  </CardContent>
                )}
              </Card>
            )
          )}
        </div>
      )}
    </div>
  );
}
