"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation } from "@tanstack/react-query";
import { toast } from "sonner";
import { Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { LogoMark } from "@/components/app/Logo";
import { errorMessage } from "@/components/app/QueryState";

import { login } from "@/lib/api";
import { saveAuth, getDashboardPath } from "@/lib/auth";

const ROLE_OPTIONS = [
  { value: "student", label: "Student" },
  { value: "teacher", label: "Teacher" },
  { value: "institution_admin", label: "Institution Admin" },
  { value: "super_admin", label: "Super Admin" },
];

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [userType, setUserType] = useState("student");
  const [formError, setFormError] = useState<string | null>(null);

  const loginMutation = useMutation({
    mutationFn: () => login(email, password, userType),
    onSuccess: (data) => {
      saveAuth(data.access_token, {
        user_id: data.user_id,
        user_type: data.user_type,
        user_name: data.user_name,
        user_email: data.user_email,
        institution_id: data.institution_id,
        cohort_id: data.cohort_id,
      });
      toast.success(`Welcome back, ${data.user_name}!`);
      router.push(getDashboardPath(data.user_type));
    },
    onError: (error: unknown) => {
      const ax = error as { response?: { status?: number } };
      const msg =
        ax.response?.status === 404
          ? "No account with that email for this role."
          : ax.response?.status === 401
            ? "Incorrect password."
            : errorMessage(error);
      setFormError(msg);
    },
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setFormError(null);
    loginMutation.mutate();
  }

  return (
    <div className="grid min-h-screen bg-background lg:grid-cols-[1.1fr_1fr]">
      {/* Brand panel */}
      <aside className="relative hidden flex-col justify-between overflow-hidden bg-ink p-12 text-white lg:flex">
        <div className="flex items-center gap-3">
          <LogoMark className="size-10 rounded-xl bg-white/10" />
          <span className="font-heading text-xl font-bold">Digi-Kul</span>
        </div>
        <div className="flex flex-col gap-5">
          <div className="eyebrow text-white/60">Digital Gurukul</div>
          <h1 className="max-w-md text-4xl font-bold leading-[1.15] text-white">
            Live classes that work on the connection you actually have.
          </h1>
          <p className="max-w-md text-[15px] leading-relaxed text-white/75">
            Audio-first live sessions, offline-ready materials and quizzes — for every corner of India.
          </p>
          <div className="mt-2 flex flex-wrap gap-2">
            {["Audio-first live sessions", "Offline sync", "Quizzes & attendance"].map((f) => (
              <span key={f} className="rounded-full border border-white/20 px-3 py-1 text-xs font-medium text-white/80">
                {f}
              </span>
            ))}
          </div>
        </div>
        <div className="text-xs text-white/50">© 2026 Digi-Kul</div>
        <div className="pointer-events-none absolute -bottom-32 -right-32 size-96 rounded-full bg-saffron/20 blur-3xl" aria-hidden />
      </aside>

      {/* Form */}
      <main className="flex items-center justify-center px-4 py-10">
        <div className="w-full max-w-sm">
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            <LogoMark className="size-10 rounded-xl" />
            <span className="font-heading text-xl font-bold">Digi-Kul</span>
          </div>
          <div className="mb-8 flex flex-col gap-1.5">
            <h2 className="text-2xl font-bold">Sign in</h2>
            <p className="text-sm text-muted-foreground">Use the account your institution gave you.</p>
          </div>

          <form onSubmit={handleSubmit} className="flex flex-col gap-5" noValidate>
            <div className="flex flex-col gap-2">
              <Label htmlFor="role-select">I am a</Label>
              <Select value={userType} onValueChange={(val) => setUserType(val ?? "student")}>
                <SelectTrigger id="role-select" className="w-full">
                  <SelectValue placeholder="Select your role" />
                </SelectTrigger>
                <SelectContent>
                  {ROLE_OPTIONS.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>
                      {opt.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex flex-col gap-2">
              <Label htmlFor="email-input">Email</Label>
              <Input
                id="email-input"
                type="email"
                placeholder="you@institution.edu"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                autoFocus
              />
            </div>

            <div className="flex flex-col gap-2">
              <Label htmlFor="password-input">Password</Label>
              <Input
                id="password-input"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
                minLength={6}
              />
            </div>

            {formError && (
              <p role="alert" className="rounded-lg bg-live-soft px-3 py-2 text-sm font-medium text-live">
                {formError}
              </p>
            )}

            <Button type="submit" size="lg" className="w-full" disabled={loginMutation.isPending || !email || password.length < 6}>
              {loginMutation.isPending ? (
                <>
                  <Loader2 className="animate-spin" data-icon="inline-start" /> Signing in…
                </>
              ) : (
                "Sign in"
              )}
            </Button>
          </form>

          <p className="mt-8 text-center text-xs text-muted-foreground">
            Students: install the Digi-Kul app for offline access and live audio on mobile data.
          </p>
        </div>
      </main>
    </div>
  );
}
