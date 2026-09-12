"use client";

import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { errorMessage } from "@/components/app/QueryState";
import { registerTeacher } from "@/lib/api";
import { getUser } from "@/lib/auth";

export function AddTeacherDialog() {
  const [open, setOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const qc = useQueryClient();
  const institutionId = getUser()?.institution_id ?? "";
  const [form, setForm] = useState({ name: "", email: "", password: "", subject: "" });

  const mut = useMutation({
    mutationFn: registerTeacher,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "teachers"] });
      setOpen(false);
      setForm({ name: "", email: "", password: "", subject: "" });
      toast.success("Teacher added — share the password with them");
    },
    onError: (e) => setError(errorMessage(e)),
  });

  if (!institutionId) return null; // super admins register teachers per institution elsewhere

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger render={<Button><Plus data-icon="inline-start" /> Add teacher</Button>} />
      <DialogContent className="sm:max-w-[440px]">
        <DialogHeader>
          <DialogTitle>Add a teacher</DialogTitle>
          <DialogDescription>Creates a teacher account in your institution.</DialogDescription>
        </DialogHeader>
        <form
          className="flex flex-col gap-4 pt-2"
          noValidate
          onSubmit={(e) => {
            e.preventDefault();
            setError(null);
            if (!form.name || !form.email || form.password.length < 6 || !form.subject) {
              setError("All fields are required; password must be at least 6 characters.");
              return;
            }
            mut.mutate({ ...form, institution_id: institutionId });
          }}
        >
          <div className="flex flex-col gap-2"><Label htmlFor="t-name">Full name *</Label><Input id="t-name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required /></div>
          <div className="flex flex-col gap-2"><Label htmlFor="t-email">Email *</Label><Input id="t-email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required /></div>
          <div className="grid grid-cols-2 gap-4">
            <div className="flex flex-col gap-2"><Label htmlFor="t-subject">Subject *</Label><Input id="t-subject" value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })} required /></div>
            <div className="flex flex-col gap-2"><Label htmlFor="t-password">Temporary password *</Label><Input id="t-password" type="text" minLength={6} value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required /></div>
          </div>
          {error && <p role="alert" className="rounded-lg bg-live-soft px-3 py-2 text-sm font-medium text-live">{error}</p>}
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
            <Button type="submit" disabled={mut.isPending}>{mut.isPending ? "Adding…" : "Add teacher"}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
