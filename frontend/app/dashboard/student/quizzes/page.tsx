"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import api from "@/lib/api";

export default function StudentQuizzesPage() {
  const query = useQuery({
    queryKey: ["student", "quiz-history"],
    queryFn: async () => {
      const { data } = await api.get("/api/students/quiz-history");
      return data;
    },
  });

  const history = query.data?.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Quiz History</h1>
        <p className="text-muted-foreground mt-1">
          Your past quiz attempts and scores.
        </p>
      </div>

      {history.length === 0 ? (
        <Card className="border-border/50">
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">
              No quiz attempts yet.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {history.map(
            (q: {
              id: string;
              quiz_set_title: string;
              score: number;
              total_questions: number;
              score_percentage: number;
              completed_at: string;
            }) => (
              <Card key={q.id} className="border-border/50">
                <CardContent className="flex items-center justify-between py-4">
                  <div className="space-y-1">
                    <p className="font-semibold">{q.quiz_set_title}</p>
                    <p className="text-sm text-muted-foreground">
                      {q.score}/{q.total_questions} correct ·{" "}
                      {new Date(q.completed_at).toLocaleDateString()}
                    </p>
                  </div>
                  <div className="text-right">
                    <span
                      className={`text-2xl font-bold ${
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
                </CardContent>
              </Card>
            )
          )}
        </div>
      )}
    </div>
  );
}
