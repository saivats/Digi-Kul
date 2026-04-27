"use client";

import { useQuery } from "@tanstack/react-query";
import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getCohort, getCohortStudents, listLecturesByCohort } from "@/lib/api";
import { ArrowLeft, Users, Video } from "lucide-react";

export default function CohortDetailPage() {
  const { cohortId } = useParams();
  const router = useRouter();

  const cohortQuery = useQuery({
    queryKey: ["cohort", cohortId],
    queryFn: () => getCohort(cohortId as string),
    enabled: !!cohortId,
  });

  const studentsQuery = useQuery({
    queryKey: ["cohort-students", cohortId],
    queryFn: () => getCohortStudents(cohortId as string),
    enabled: !!cohortId,
  });

  const lecturesQuery = useQuery({
    queryKey: ["cohort-lectures", cohortId],
    queryFn: () => listLecturesByCohort(cohortId as string),
    enabled: !!cohortId,
  });

  if (cohortQuery.isLoading) {
    return <div>Loading cohort details...</div>;
  }

  const cohort = cohortQuery.data?.data;
  if (!cohort) {
    return <div>Cohort not found.</div>;
  }

  const students = studentsQuery.data?.data || [];
  const lectures = lecturesQuery.data?.data || [];

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="outline" size="icon" onClick={() => router.back()}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">{cohort.name}</h1>
          <p className="text-muted-foreground mt-1">
            Enrollment Code: <span className="font-mono text-foreground">{cohort.enrollment_code}</span>
          </p>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border-border/50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Status</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              <Badge variant={cohort.is_active ? "default" : "secondary"}>
                {cohort.is_active ? "Active" : "Inactive"}
              </Badge>
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              {cohort.academic_year ? `Academic Year: ${cohort.academic_year}` : "No specific year"}
            </p>
          </CardContent>
        </Card>

        <Card className="border-border/50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Students</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{students.length}</div>
            <p className="text-xs text-muted-foreground mt-1">
              {cohort.max_students ? `out of ${cohort.max_students} max limit` : "No capacity limit"}
            </p>
          </CardContent>
        </Card>

        <Card className="border-border/50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Lectures</CardTitle>
            <Video className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{lectures.length}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Scheduled and completed
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card className="border-border/50">
          <CardHeader>
            <CardTitle className="text-lg">Recent Lectures</CardTitle>
          </CardHeader>
          <CardContent>
            {lectures.length === 0 ? (
              <p className="text-sm text-muted-foreground">No lectures scheduled yet.</p>
            ) : (
              <div className="space-y-4">
                {lectures.slice(0, 5).map((lecture: { id: string; title: string; scheduled_time: string; status: string }) => (
                  <div key={lecture.id} className="flex justify-between items-center border-b pb-2 last:border-0 last:pb-0">
                    <div>
                      <p className="font-medium">{lecture.title}</p>
                      <p className="text-xs text-muted-foreground">
                        {new Date(lecture.scheduled_time).toLocaleString()}
                      </p>
                    </div>
                    <Badge variant={lecture.status === "completed" ? "secondary" : "default"}>
                      {lecture.status}
                    </Badge>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="border-border/50">
          <CardHeader>
            <CardTitle className="text-lg">Enrolled Students</CardTitle>
          </CardHeader>
          <CardContent>
            {students.length === 0 ? (
              <p className="text-sm text-muted-foreground">No students enrolled yet.</p>
            ) : (
              <div className="space-y-4">
                {students.map((student: { id: string; name?: string; email?: string }) => (
                  <div key={student.id} className="flex justify-between items-center border-b pb-2 last:border-0 last:pb-0">
                    <div>
                      <p className="font-medium">{student.name || "Unknown Student"}</p>
                      <p className="text-xs text-muted-foreground">{student.email}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
