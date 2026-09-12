"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState, errorMessage } from "@/components/app/QueryState";
import { Button } from "@/components/ui/button";
import { getUser } from "@/lib/auth";

export interface Person {
  id: string;
  name: string;
  email: string;
  is_active: boolean;
  last_login: string | null;
  subject?: string;
  student_id?: string | null;
}

export function PeopleTable({
  people,
  query,
  extraLabel,
  extraKey,
  queryKey,
  toggle,
  emptyTitle,
}: {
  people: Person[];
  query: { isLoading: boolean; isError: boolean; error: unknown; refetch: () => void };
  extraLabel: string;
  extraKey: "subject" | "student_id";
  queryKey: string[];
  toggle: (id: string) => Promise<unknown>;
  emptyTitle: string;
}) {
  const qc = useQueryClient();
  const role = getUser()?.user_type;
  const canToggle = role === "institution_admin" || role === "admin" || role === "super_admin";
  const mut = useMutation({
    mutationFn: toggle,
    onSuccess: (data: unknown) => {
      qc.invalidateQueries({ queryKey });
      const active = (data as { data?: { is_active?: boolean } })?.data?.is_active;
      toast.success(active === false ? "Account deactivated" : "Account activated");
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  return (
    <section className="panel overflow-hidden">
      <QueryState isLoading={query.isLoading} isError={query.isError} error={query.error} refetch={query.refetch} isEmpty={people.length === 0} emptyTitle={emptyTitle} rows={4}>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-left">
                <th className="px-5 py-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Name</th>
                <th className="px-5 py-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Email</th>
                <th className="px-5 py-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">{extraLabel}</th>
                <th className="px-5 py-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Status</th>
                <th className="px-5 py-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Last login</th>
                {canToggle && <th className="px-5 py-3 text-right text-xs font-semibold uppercase tracking-wider text-muted-foreground">Actions</th>}
              </tr>
            </thead>
            <tbody>
              {people.map((p) => (
                <tr key={p.id} className="border-b border-border/60 last:border-0 hover:bg-muted/50">
                  <td className="px-5 py-3 font-semibold">{p.name}</td>
                  <td className="px-5 py-3 text-muted-foreground">{p.email}</td>
                  <td className="px-5 py-3">{extraKey === "student_id" ? <span className="font-mono text-xs">{p.student_id ?? "—"}</span> : (p.subject ?? "—")}</td>
                  <td className="px-5 py-3"><StatusBadge status={p.is_active ? "active" : "inactive"} /></td>
                  <td className="px-5 py-3 text-xs text-muted-foreground">{p.last_login ? new Date(p.last_login).toLocaleDateString() : "Never"}</td>
                  {canToggle && (
                    <td className="px-5 py-3 text-right">
                      <Button size="sm" variant={p.is_active ? "outline" : "default"} disabled={mut.isPending} onClick={() => { if (p.is_active && !confirm(`Deactivate ${p.name}? They won't be able to sign in.`)) return; mut.mutate(p.id); }}>
                        {p.is_active ? "Deactivate" : "Activate"}
                      </Button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </QueryState>
    </section>
  );
}
