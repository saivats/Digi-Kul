"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { listTeachers } from "@/lib/api";

export default function AdminTeachersPage() {
  const query = useQuery({
    queryKey: ["admin", "teachers"],
    queryFn: listTeachers,
  });

  const teachers = query.data?.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Teachers</h1>
        <p className="text-muted-foreground mt-1">
          Manage teachers in your institution.
        </p>
      </div>

      <Card className="border-border/50">
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border/50">
                  <th className="text-left p-4 font-medium text-muted-foreground">Name</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Email</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Subject</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Status</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Last Login</th>
                </tr>
              </thead>
              <tbody>
                {teachers.map(
                  (t: {
                    id: string;
                    name: string;
                    email: string;
                    subject: string;
                    is_active: boolean;
                    last_login: string | null;
                  }) => (
                    <tr key={t.id} className="border-b border-border/30 hover:bg-muted/50">
                      <td className="p-4 font-medium">{t.name}</td>
                      <td className="p-4 text-muted-foreground">{t.email}</td>
                      <td className="p-4">{t.subject}</td>
                      <td className="p-4">
                        <Badge variant={t.is_active ? "default" : "secondary"}>
                          {t.is_active ? "Active" : "Inactive"}
                        </Badge>
                      </td>
                      <td className="p-4 text-muted-foreground text-xs">
                        {t.last_login
                          ? new Date(t.last_login).toLocaleDateString()
                          : "Never"}
                      </td>
                    </tr>
                  )
                )}
                {teachers.length === 0 && (
                  <tr>
                    <td colSpan={5} className="p-8 text-center text-muted-foreground">
                      No teachers found.
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
