"use client";

import { useEffect, useState, type ReactNode } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import { LogOut } from "lucide-react";
import { toast } from "sonner";
import { getUser, clearAuth, type AuthUser } from "@/lib/auth";
import { logout as apiLogout } from "@/lib/api";
import { Logo } from "@/components/app/Logo";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

function getNavLinks(userType: string) {
  const isAdmin =
    userType === "institution_admin" || userType === "super_admin" || userType === "admin";
  const base = `/dashboard/${isAdmin ? "admin" : userType}`;
  const common = [{ href: base, label: "Overview" }];

  if (userType === "teacher") {
    return [
      ...common,
      { href: `${base}/cohorts`, label: "Cohorts" },
      { href: `${base}/lectures`, label: "Lectures" },
    ];
  }
  if (userType === "student") {
    return [
      ...common,
      { href: `${base}/cohorts`, label: "My Cohorts" },
      { href: `${base}/quizzes`, label: "Quizzes" },
    ];
  }
  const adminLinks = [
    ...common,
    { href: `${base}/teachers`, label: "Teachers" },
    { href: `${base}/students`, label: "Students" },
    { href: `${base}/cohorts`, label: "Cohorts" },
  ];
  if (userType === "super_admin" || userType === "admin") {
    adminLinks.splice(1, 0, { href: `${base}/institutions`, label: "Institutions" });
  }
  return adminLinks;
}

const ROLE_LABEL: Record<string, string> = {
  teacher: "Teacher",
  student: "Student",
  institution_admin: "Institution admin",
  super_admin: "Super admin",
  admin: "Platform admin",
};

export default function DashboardLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [user, setUser] = useState<AuthUser | null>(null);

  useEffect(() => {
    const u = getUser();
    if (!u) {
      router.replace("/login");
      return;
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setUser(u);
  }, [router]);

  if (!user) return null;

  const navLinks = getNavLinks(user.user_type);
  const initials = (user.user_name || "?")
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  async function handleLogout() {
    try {
      await apiLogout(); // server-side audit; token is stateless
    } catch {
      /* logging out locally regardless */
    }
    clearAuth();
    toast.success("Signed out");
    router.replace("/login");
  }

  return (
    <div className="flex min-h-screen flex-col bg-background">
      <header className="sticky top-0 z-40 border-b border-border bg-card">
        <div className="mx-auto flex h-16 max-w-7xl items-center gap-6 px-4 sm:px-6">
          <Logo href={navLinks[0].href} />
          <span className="hidden h-6 w-px bg-border md:block" />
          <nav className="hidden items-center gap-1 md:flex" aria-label="Primary">
            {navLinks.map((link, idx) => {
              const isActive = idx === 0 ? pathname === link.href : pathname.startsWith(link.href);
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  aria-current={isActive ? "page" : undefined}
                  className={cn(
                    "rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                    isActive
                      ? "bg-ink-soft font-semibold text-ink"
                      : "text-muted-foreground hover:bg-muted hover:text-foreground"
                  )}
                >
                  {link.label}
                </Link>
              );
            })}
          </nav>

          <div className="ml-auto flex items-center gap-2">
            <DropdownMenu>
              <DropdownMenuTrigger className="flex cursor-pointer items-center gap-2 rounded-lg px-2 py-1.5 outline-none transition-colors hover:bg-muted focus-visible:ring-2 focus-visible:ring-ring">
                <Avatar className="size-8">
                  <AvatarFallback className="bg-ink-soft text-xs font-bold text-ink">
                    {initials}
                  </AvatarFallback>
                </Avatar>
                <span className="hidden flex-col items-start leading-tight sm:flex">
                  <span className="text-sm font-semibold">{user.user_name}</span>
                  <span className="text-[11px] text-muted-foreground">
                    {ROLE_LABEL[user.user_type] ?? user.user_type}
                  </span>
                </span>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-56">
                <div className="px-2 py-1.5 text-xs text-muted-foreground">{user.user_email}</div>
                <DropdownMenuItem
                  onClick={handleLogout}
                  className="cursor-pointer text-destructive focus:text-destructive"
                >
                  <LogOut className="size-4" /> Sign out
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
        {/* Mobile nav */}
        <nav className="flex gap-1 overflow-x-auto border-t border-border px-3 py-2 md:hidden" aria-label="Primary">
          {navLinks.map((link, idx) => {
            const isActive = idx === 0 ? pathname === link.href : pathname.startsWith(link.href);
            return (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  "shrink-0 rounded-lg px-3 py-1.5 text-sm font-medium",
                  isActive ? "bg-ink-soft text-ink" : "text-muted-foreground"
                )}
              >
                {link.label}
              </Link>
            );
          })}
        </nav>
      </header>

      <main className="mx-auto w-full max-w-7xl flex-1 px-4 py-6 sm:px-6 sm:py-8">
        {children}
      </main>
    </div>
  );
}
