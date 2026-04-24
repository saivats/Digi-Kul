"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { getTeacherProfile, listLectures, listCohorts } from "@/lib/api";

export default function TeacherDashboard() {
  const profileQuery = useQuery({
    queryKey: ["teacher", "profile"],
    queryFn: getTeacherProfile,
  });

  const lecturesQuery = useQuery({
    queryKey: ["teacher", "lectures"],
    queryFn: listLectures,
  });

  const cohortsQuery = useQuery({
    queryKey: ["teacher", "cohorts"],
    queryFn: listCohorts,
  });

  const profile = profileQuery.data?.data;
  const lectures = lecturesQuery.data?.data ?? [];
  const cohorts = cohortsQuery.data?.data ?? [];
  const liveLectures = lectures.filter(
    (l: { status: string }) => l.status === "live"
  );
  const scheduledLectures = lectures.filter(
    (l: { status: string }) => l.status === "scheduled"
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">
          Welcome, {profile?.name ?? "Teacher"}
        </h1>
        <p className="text-muted-foreground mt-1">
          Here&apos;s what&apos;s happening in your classes today.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        <StatCard title="My Cohorts" value={cohorts.length} />
        <StatCard title="Total Lectures" value={lectures.length} />
        <StatCard
          title="Live Now"
          value={liveLectures.length}
          accent
        />
        <StatCard title="Scheduled" value={scheduledLectures.length} />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="border-border/50">
          <CardHeader>
            <CardTitle className="text-lg">Live Sessions</CardTitle>
          </CardHeader>
          <CardContent>
            {liveLectures.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No live sessions right now.
              </p>
            ) : (
              <div className="space-y-3">
                {liveLectures.map(
                  (lec: { id: string; title: string; cohort_id: string }) => (
                    <div
                      key={lec.id}
                      className="flex items-center justify-between rounded-lg border border-border/50 p-3"
                    >
                      <div>
                        <p className="font-medium">{lec.title}</p>
                        <p className="text-xs text-muted-foreground">
                          Cohort: {lec.cohort_id?.slice(0, 8)}…
                        </p>
                      </div>
                      <Badge
                        variant="default"
                        className="bg-green-500/10 text-green-500 border-green-500/20"
                      >
                        Live
                      </Badge>
                    </div>
                  )
                )}
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="border-border/50">
          <CardHeader>
            <CardTitle className="text-lg">Upcoming Lectures</CardTitle>
          </CardHeader>
          <CardContent>
            {scheduledLectures.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No upcoming lectures.
              </p>
            ) : (
              <div className="space-y-3">
                {scheduledLectures.slice(0, 5).map(
                  (lec: {
                    id: string;
                    title: string;
                    scheduled_time: string;
                  }) => (
                    <div
                      key={lec.id}
                      className="flex items-center justify-between rounded-lg border border-border/50 p-3"
                    >
                      <div>
                        <p className="font-medium">{lec.title}</p>
                        <p className="text-xs text-muted-foreground">
                          {new Date(lec.scheduled_time).toLocaleString()}
                        </p>
                      </div>
                      <Badge variant="secondary">Scheduled</Badge>
                    </div>
                  )
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function StatCard({
  title,
  value,
  accent,
}: {
  title: string;
  value: number;
  accent?: boolean;
}) {
  return (
    <Card className="border-border/50">
      <CardContent className="pt-6">
        <p className="text-sm text-muted-foreground">{title}</p>
        <p
          className={`text-3xl font-bold mt-1 ${
            accent ? "text-green-500" : ""
          }`}
        >
          {value}
        </p>
      </CardContent>
    </Card>
  );
}
