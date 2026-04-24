"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { listStudents } from "@/lib/api";

export default function AdminStudentsPage() {
  const query = useQuery({
    queryKey: ["admin", "students"],
    queryFn: listStudents,
  });

  const students = query.data?.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Students</h1>
        <p className="text-muted-foreground mt-1">
          Manage students in your institution.
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
                  <th className="text-left p-4 font-medium text-muted-foreground">Student ID</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Status</th>
                  <th className="text-left p-4 font-medium text-muted-foreground">Last Login</th>
                </tr>
              </thead>
              <tbody>
                {students.map(
                  (s: {
                    id: string;
                    name: string;
                    email: string;
                    student_id: string | null;
                    is_active: boolean;
                    last_login: string | null;
                  }) => (
                    <tr key={s.id} className="border-b border-border/30 hover:bg-muted/50">
                      <td className="p-4 font-medium">{s.name}</td>
                      <td className="p-4 text-muted-foreground">{s.email}</td>
                      <td className="p-4 font-mono text-xs">{s.student_id ?? "—"}</td>
                      <td className="p-4">
                        <Badge variant={s.is_active ? "default" : "secondary"}>
                          {s.is_active ? "Active" : "Inactive"}
                        </Badge>
                      </td>
                      <td className="p-4 text-muted-foreground text-xs">
                        {s.last_login
                          ? new Date(s.last_login).toLocaleDateString()
                          : "Never"}
                      </td>
                    </tr>
                  )
                )}
                {students.length === 0 && (
                  <tr>
                    <td colSpan={5} className="p-8 text-center text-muted-foreground">
                      No students found.
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
