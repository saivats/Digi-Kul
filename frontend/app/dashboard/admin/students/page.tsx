"use client";

import { useQuery } from "@tanstack/react-query";
import { listStudents, toggleStudentActive } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { PeopleTable } from "@/components/app/PeopleTable";

export default function AdminStudentsPage() {
  const query = useQuery({ queryKey: ["admin", "students"], queryFn: listStudents });
  return (
    <div className="flex flex-col gap-7">
      <PageHeader title="Students" description="Everyone registered as a student in your institution." />
      <PeopleTable people={query.data?.data ?? []} query={query} extraLabel="Student ID" extraKey="student_id" queryKey={["admin", "students"]} toggle={toggleStudentActive} emptyTitle="No students yet" />
    </div>
  );
}
