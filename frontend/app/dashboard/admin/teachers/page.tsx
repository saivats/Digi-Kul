"use client";

import { useQuery } from "@tanstack/react-query";
import { listTeachers, toggleTeacherActive } from "@/lib/api";
import { PageHeader } from "@/components/app/PageHeader";
import { PeopleTable } from "@/components/app/PeopleTable";
import { AddTeacherDialog } from "@/components/AddTeacherDialog";

export default function AdminTeachersPage() {
  const query = useQuery({ queryKey: ["admin", "teachers"], queryFn: listTeachers });
  return (
    <div className="flex flex-col gap-7">
      <PageHeader title="Teachers" description="Teaching staff in your institution." actions={<AddTeacherDialog />} />
      <PeopleTable people={query.data?.data ?? []} query={query} extraLabel="Subject" extraKey="subject" queryKey={["admin", "teachers"]} toggle={toggleTeacherActive} emptyTitle="No teachers yet" />
    </div>
  );
}
