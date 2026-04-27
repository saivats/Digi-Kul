"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { listInstitutions } from "@/lib/api";
import { CreateInstitutionDialog } from "@/components/CreateInstitutionDialog";
import { EditInstitutionDialog } from "@/components/EditInstitutionDialog";

export default function AdminInstitutionsPage() {
  const query = useQuery({
    queryKey: ["admin", "institutions"],
    queryFn: listInstitutions,
  });

  const institutions = query.data?.data ?? [];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Institutions</h1>
          <p className="text-muted-foreground mt-1">
            All registered institutions on the platform.
          </p>
        </div>
        <CreateInstitutionDialog />
      </div>

      <Card className="border-border/50">
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border/50">
                  <th className="text-left p-4 font-medium text-muted-foreground">Name</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Domain</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Contact</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Status</th>
                  <th className="text-right p-4 font-medium text-muted-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {institutions.map(
                  (inst: {
                    id: string;
                    name: string;
                    domain: string;
                    contact_email: string | null;
                    is_active: boolean;
                  }) => (
                    <tr key={inst.id} className="border-b border-border/30 hover:bg-muted/50">
                      <td className="p-4 font-medium">{inst.name}</td>
                      <td className="p-4 text-muted-foreground">{inst.domain}</td>
                      <td className="p-4 text-muted-foreground">
                        {inst.contact_email ?? "—"}
                      </td>
                      <td className="p-4">
                        <span
                          className={`text-xs font-medium px-2 py-1 rounded-full ${
                            inst.is_active
                              ? "bg-green-500/10 text-green-500"
                              : "bg-red-500/10 text-red-500"
                          }`}
                        >
                          {inst.is_active ? "Active" : "Inactive"}
                        </span>
                      </td>
                      <td className="p-4 text-right">
                        <EditInstitutionDialog institution={inst} />
                      </td>
                    </tr>
                  )
                )}
                {institutions.length === 0 && (
                  <tr>
                    <td colSpan={4} className="p-8 text-center text-muted-foreground">
                      No institutions found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
