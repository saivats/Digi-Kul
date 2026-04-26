"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { listLectures, listCohorts, createLecture, startLecture, endLecture } from "@/lib/api";
import { Plus, Play, Square, Video } from "lucide-react";
import { toast } from "sonner";

export default function TeacherLecturesPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    cohort_id: "",
    title: "",
    description: "",
    scheduled_time: "",
    duration: 60,
  });

  const lecturesQuery = useQuery({
    queryKey: ["teacher", "lectures"],
    queryFn: listLectures,
  });

  const cohortsQuery = useQuery({
    queryKey: ["teacher", "cohorts"],
    queryFn: listCohorts,
  });

  const lectures = lecturesQuery.data?.data ?? [];
  const cohorts = cohortsQuery.data?.data ?? [];

  const createMutation = useMutation({
    mutationFn: createLecture,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["teacher", "lectures"] });
      setOpen(false);
      setFormData({ cohort_id: "", title: "", description: "", scheduled_time: "", duration: 60 });
      setFormError(null);
      toast.success("Lecture created successfully");
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (err: any) => {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      setFormError(err?.response?.data?.detail || "Failed to create lecture");
    },
  });

  const startMutation = useMutation({
    mutationFn: startLecture,
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["teacher", "lectures"] });
      toast.success("Lecture started — you are live!");
      router.push(`/teacher/session/${variables}`);
    },
  });

  const endMutation = useMutation({
    mutationFn: endLecture,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["teacher", "lectures"] });
      toast.success("Lecture ended");
    },
  });

  function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    setFormError(null);
    if (!formData.cohort_id || !formData.title || !formData.scheduled_time) {
      setFormError("Cohort, title, and scheduled time are required");
      return;
    }
    createMutation.mutate(formData);
  }

  const liveLectures = lectures.filter((l: { status: string }) => l.status === "live");
  const scheduledLectures = lectures.filter((l: { status: string }) => l.status === "scheduled");
  const endedLectures = lectures.filter((l: { status: string }) => l.status === "ended");

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Lectures</h1>
          <p className="text-muted-foreground mt-1">
            Schedule and manage your live sessions.
          </p>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger
            render={
              <Button>
                <Plus className="mr-2 h-4 w-4" />
                Schedule Lecture
              </Button>
            }
          />
          <DialogContent className="sm:max-w-[425px]">
            <DialogHeader>
              <DialogTitle>Schedule New Lecture</DialogTitle>
              <DialogDescription>
                Create a new live session for one of your cohorts.
              </DialogDescription>
            </DialogHeader>
            <form onSubmit={handleCreate} className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label htmlFor="lecture-cohort">Cohort *</Label>
                <Select value={formData.cohort_id} onValueChange={(val) => setFormData({ ...formData, cohort_id: val ?? "" })}>
                  <SelectTrigger id="lecture-cohort">
                    <SelectValue placeholder="Select a cohort" />
                  </SelectTrigger>
                  <SelectContent>
                    {cohorts.map((c: { id: string; name: string }) => (
                      <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="lecture-title">Title *</Label>
                <Input
                  id="lecture-title"
                  placeholder="e.g. Introduction to Physics"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="lecture-desc">Description</Label>
                <Textarea
                  id="lecture-desc"
                  placeholder="Topic overview..."
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="resize-none"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="lecture-time">Scheduled Time *</Label>
                  <Input
                    id="lecture-time"
                    type="datetime-local"
                    value={formData.scheduled_time}
                    onChange={(e) => setFormData({ ...formData, scheduled_time: e.target.value })}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lecture-duration">Duration (min)</Label>
                  <Input
                    id="lecture-duration"
                    type="number"
                    min={10}
                    max={300}
                    value={formData.duration}
                    onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value) || 60 })}
                  />
                </div>
              </div>
              {formError && <p className="text-sm font-medium text-destructive">{formError}</p>}
              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
                <Button type="submit" disabled={createMutation.isPending}>
                  {createMutation.isPending ? "Creating..." : "Schedule"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {liveLectures.length > 0 && (
        <Card className="border-green-500/30 bg-green-500/5">
          <CardHeader>
            <CardTitle className="text-lg text-green-500">Live Now</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {liveLectures.map((lec: { id: string; title: string; cohort_id: string }) => (
              <div key={lec.id} className="flex items-center justify-between rounded-lg border border-green-500/20 p-3">
                <div>
                  <p className="font-medium">{lec.title}</p>
                  <p className="text-xs text-muted-foreground">Cohort: {lec.cohort_id?.slice(0, 8)}…</p>
                </div>
                <div className="flex items-center space-x-2">
                  <Button
                    size="sm"
                    variant="default"
                    className="bg-green-600 hover:bg-green-700 text-white"
                    onClick={() => router.push(`/teacher/session/${lec.id}`)}
                  >
                    <Video className="mr-1 h-3 w-3" /> Join Session
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    className="text-red-500 border-red-500/30"
                    onClick={() => endMutation.mutate(lec.id)}
                    disabled={endMutation.isPending}
                  >
                    <Square className="mr-1 h-3 w-3" /> End
                  </Button>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      <Card className="border-border/50">
        <CardHeader>
          <CardTitle className="text-lg">Scheduled</CardTitle>
        </CardHeader>
        <CardContent>
          {scheduledLectures.length === 0 ? (
            <p className="text-sm text-muted-foreground">No upcoming lectures.</p>
          ) : (
            <div className="space-y-3">
              {scheduledLectures.map((lec: { id: string; title: string; scheduled_time: string; cohort_id: string }) => (
                <div key={lec.id} className="flex items-center justify-between rounded-lg border border-border/50 p-3">
                  <div>
                    <p className="font-medium">{lec.title}</p>
                    <p className="text-xs text-muted-foreground">
                      {new Date(lec.scheduled_time).toLocaleString()}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="secondary">Scheduled</Badge>
                    <Button
                      size="sm"
                      onClick={() => startMutation.mutate(lec.id)}
                      disabled={startMutation.isPending}
                    >
                      <Play className="mr-1 h-3 w-3" /> Go Live
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {endedLectures.length > 0 && (
        <Card className="border-border/50">
          <CardHeader>
            <CardTitle className="text-lg">Past Lectures</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {endedLectures.slice(0, 10).map((lec: { id: string; title: string; scheduled_time: string }) => (
                <div key={lec.id} className="flex items-center justify-between rounded-lg border border-border/50 p-3 opacity-70">
                  <div>
                    <p className="font-medium">{lec.title}</p>
                    <p className="text-xs text-muted-foreground">
                      {new Date(lec.scheduled_time).toLocaleString()}
                    </p>
                  </div>
                  <Badge variant="secondary">Ended</Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
