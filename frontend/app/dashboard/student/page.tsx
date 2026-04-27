"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { getStudentProfile } from "@/lib/api";
import api from "@/lib/api";

export default function StudentDashboard() {
  const profileQuery = useQuery({
    queryKey: ["student", "profile"],
    queryFn: getStudentProfile,
  });

  const cohortsQuery = useQuery({
    queryKey: ["student", "cohorts"],
    queryFn: async () => {
      const { data } = await api.get("/api/students/cohorts");
      return data;
    },
  });

  const quizHistoryQuery = useQuery({
    queryKey: ["student", "quiz-history"],
    queryFn: async () => {
      const { data } = await api.get("/api/students/quiz-history");
      return data;
    },
  });

  const profile = profileQuery.data?.data;
  const cohorts = cohortsQuery.data?.data ?? [];
  const quizHistory = quizHistoryQuery.data?.data ?? [];
  const avgScore =
    quizHistory.length > 0
      ? Math.round(
          quizHistory.reduce(
            (sum: number, q: { score_percentage: number }) =>
              sum + (q.score_percentage ?? 0),
            0
          ) / quizHistory.length
        )
      : 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">
          Welcome, {profile?.name ?? "Student"}
        </h1>
        <p className="text-muted-foreground mt-1">
          Your learning dashboard.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border-border/50">
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">My Cohorts</p>
            <p className="text-3xl font-bold mt-1">{cohorts.length}</p>
          </CardContent>
        </Card>
        <Card className="border-border/50">
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Quizzes Taken</p>
            <p className="text-3xl font-bold mt-1">{quizHistory.length}</p>
          </CardContent>
        </Card>
        <Card className="border-border/50">
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">Avg Quiz Score</p>
            <p className="text-3xl font-bold mt-1 text-primary">{avgScore}%</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="border-border/50">
          <CardHeader>
            <CardTitle className="text-lg">My Cohorts</CardTitle>
          </CardHeader>
          <CardContent>
            {cohorts.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Not enrolled in any cohort yet.
              </p>
            ) : (
              <div className="space-y-3">
                {cohorts.map(
                  (c: {
                    id: string;
                    name: string;
                    is_active: boolean;
                  }) => (
                    <div
                      key={c.id}
                      className="flex items-center justify-between rounded-lg border border-border/50 p-3"
                    >
                      <p className="font-medium">{c.name}</p>
                      <Badge variant={c.is_active ? "default" : "secondary"}>
                        {c.is_active ? "Active" : "Inactive"}
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
            <CardTitle className="text-lg">Recent Quiz Results</CardTitle>
          </CardHeader>
          <CardContent>
            {quizHistory.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No quiz attempts yet.
              </p>
            ) : (
              <div className="space-y-3">
                {quizHistory.slice(0, 5).map(
                  (q: {
                    id: string;
                    quiz_set_title: string;
                    score: number;
                    total_questions: number;
                    score_percentage: number;
                  }) => (
                    <div
                      key={q.id}
                      className="flex items-center justify-between rounded-lg border border-border/50 p-3"
                    >
                      <div>
                        <p className="font-medium">{q.quiz_set_title}</p>
                        <p className="text-xs text-muted-foreground">
                          {q.score}/{q.total_questions} correct
                        </p>
                      </div>
                      <span
                        className={`text-sm font-bold ${
                          q.score_percentage >= 70
                            ? "text-green-500"
                            : q.score_percentage >= 40
                              ? "text-yellow-500"
                              : "text-red-500"
                        }`}
                      >
                        {q.score_percentage}%
                      </span>
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
