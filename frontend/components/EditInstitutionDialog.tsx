"use client";

import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { updateInstitution, deleteInstitution } from "@/lib/api";
import { Edit, Trash2 } from "lucide-react";

interface EditInstitutionDialogProps {
  institution: {
    id: string;
    name: string;
    domain: string;
    contact_email: string | null;
    is_active: boolean;
  };
}

export function EditInstitutionDialog({ institution }: EditInstitutionDialogProps) {
  const [open, setOpen] = useState(false);
  const queryClient = useQueryClient();
  const [error, setError] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    name: institution.name,
    domain: institution.domain,
    contact_email: institution.contact_email || "",
  });

  const updateMutation = useMutation({
    mutationFn: (data: any) => updateInstitution(institution.id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "institutions"] });
      setOpen(false);
      setError(null);
    },
    onError: (err: any) => {
      setError(err?.response?.data?.detail || "Failed to update institution");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: () => deleteInstitution(institution.id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "institutions"] });
      setOpen(false);
      setError(null);
    },
    onError: (err: any) => {
      setError(err?.response?.data?.detail || "Failed to delete institution");
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!formData.name || !formData.domain) {
      setError("Name and Domain are required");
      return;
    }
    updateMutation.mutate(formData);
  };

  const handleDelete = () => {
    if (confirm("Are you sure you want to delete this institution? This action cannot be undone.")) {
      deleteMutation.mutate();
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger
        render={
          <Button variant="ghost" size="sm">
            <Edit className="h-4 w-4" />
          </Button>
        }
      />
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Edit Institution</DialogTitle>
          <DialogDescription>
            Update institution details or remove it from the platform.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 pt-4">
          <div className="space-y-2">
            <Label htmlFor="edit-name">Institution Name *</Label>
            <Input
              id="edit-name"
              placeholder="e.g. Acme University"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="edit-domain">Domain *</Label>
            <Input
              id="edit-domain"
              placeholder="e.g. acme.edu"
              value={formData.domain}
              onChange={(e) => setFormData({ ...formData, domain: e.target.value })}
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="edit-contact_email">Contact Email</Label>
            <Input
              id="edit-contact_email"
              type="email"
              placeholder="e.g. admin@acme.edu"
              value={formData.contact_email}
              onChange={(e) => setFormData({ ...formData, contact_email: e.target.value })}
            />
          </div>
          {error && <p className="text-sm font-medium text-destructive">{error}</p>}
          <DialogFooter className="flex justify-between items-center sm:justify-between">
            <Button
              type="button"
              variant="destructive"
              onClick={handleDelete}
              disabled={deleteMutation.isPending || updateMutation.isPending}
            >
              {deleteMutation.isPending ? "Deleting..." : <Trash2 className="h-4 w-4 mr-2" />}
              {deleteMutation.isPending ? "" : "Delete"}
            </Button>
            <div className="flex space-x-2">
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={updateMutation.isPending || deleteMutation.isPending}>
                {updateMutation.isPending ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
