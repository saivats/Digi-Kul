"use client";

import { useQuery } from "@tanstack/react-query";
import { listInstitutions } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { StatusBadge } from "@/components/app/StatusBadge";
import { QueryState } from "@/components/app/QueryState";
import { CreateInstitutionDialog } from "@/components/CreateInstitutionDialog";
import { EditInstitutionDialog } from "@/components/EditInstitutionDialog";

interface Inst { id: string; name: string; domain: string; contact_email: string | null; is_active: boolean }

export default function AdminInstitutionsPage() {
  const query = useQuery({ queryKey: ["admin", "institutions"], queryFn: listInstitutions });
  const institutions: Inst[] = query.data?.data ?? [];
  return (
    <div className="flex flex-col gap-7">
      <PageHeader title="Institutions" description="All institutions registered on the platform." actions={<CreateInstitutionDialog />} />
      <section className="panel overflow-hidden">
        <QueryState isLoading={query.isLoading} isError={query.isError} error={query.error} refetch={query.refetch} isEmpty={institutions.length === 0} emptyTitle="No institutions yet" rows={3}>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  {["Name", "Domain", "Contact", "Status"].map((h) => (
                    <th key={h} className="px-5 py-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">{h}</th>
                  ))}
                  <th className="px-5 py-3 text-right text-xs font-semibold uppercase tracking-wider text-muted-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {institutions.map((inst) => (
                  <tr key={inst.id} className="border-b border-border/60 last:border-0 hover:bg-muted/50">
                    <td className="px-5 py-3 font-semibold">{inst.name}</td>
                    <td className="px-5 py-3 text-muted-foreground">{inst.domain}</td>
                    <td className="px-5 py-3 text-muted-foreground">{inst.contact_email ?? "—"}</td>
                    <td className="px-5 py-3"><StatusBadge status={inst.is_active ? "active" : "inactive"} /></td>
                    <td className="px-5 py-3 text-right"><EditInstitutionDialog institution={inst} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </QueryState>
      </section>
    </div>
  );
}
