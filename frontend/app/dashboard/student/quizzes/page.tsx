"use client";

import { useQuery } from "@tanstack/react-query";
import { listStudentQuizHistory } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { QueryState } from "@/components/app/QueryState";
import { fmtDateTime } from "@/components/app/DateChip";

interface Attempt { id: string; quiz_sets?: { title?: string }; total_questions?: number; correct_answers?: number; is_completed?: boolean; finished_at?: string | null; started_at?: string; attempt_number?: number }

export default function StudentQuizzesPage() {
  const query = useQuery({ queryKey: ["student", "quiz-history"], queryFn: listStudentQuizHistory });
  const history: Attempt[] = query.data?.data ?? [];

  return (
    <div className="flex flex-col gap-7">
      <PageHeader title="Quiz results" description="Your attempts and scores. Quizzes are taken in the mobile app." />
      <section className="panel overflow-hidden">
        <QueryState isLoading={query.isLoading} isError={query.isError} error={query.error} refetch={query.refetch} isEmpty={history.length === 0} emptyTitle="No attempts yet" rows={3}>
          <ul className="divide-y divide-border">
            {history.map((q) => {
              const total = q.total_questions ?? 0;
              const pct = q.is_completed && total ? Math.round(((q.correct_answers ?? 0) / total) * 100) : null;
              return (
                <li key={q.id} className="flex items-center gap-4 px-5 py-4">
                  <div className="min-w-0 flex-1">
                    <div className="truncate font-semibold">{q.quiz_sets?.title ?? "Quiz"}{q.attempt_number && q.attempt_number > 1 ? ` · attempt ${q.attempt_number}` : ""}</div>
                    <div className="text-[13px] text-muted-foreground">
                      {q.is_completed ? `${q.correct_answers ?? 0}/${total} correct · ${fmtDateTime(q.finished_at || q.started_at || "")}` : "In progress"}
                    </div>
                  </div>
                  {pct != null ? (
                    <span className={`font-heading text-2xl font-bold ${pct >= 70 ? "text-online" : pct >= 40 ? "text-saffron-ink" : "text-live"}`}>{pct}%</span>
                  ) : (
                    <span className="text-sm text-muted-foreground">—</span>
                  )}
                </li>
              );
            })}
          </ul>
        </QueryState>
      </section>
    </div>
  );
}
