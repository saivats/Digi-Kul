import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function HomePage() {
  return (
    <div className="min-h-screen flex flex-col bg-gradient-to-br from-background via-background to-primary/5">
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-20 right-20 h-96 w-96 rounded-full bg-primary/5 blur-3xl" />
        <div className="absolute bottom-20 left-20 h-96 w-96 rounded-full bg-chart-1/5 blur-3xl" />
      </div>

      <header className="relative z-10 border-b border-border/30 bg-card/50 backdrop-blur-xl">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <div className="flex items-center gap-2 font-bold text-lg tracking-tight">
            <span className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary font-bold text-sm">
              D
            </span>
            Digi-Kul
          </div>
          <Link href="/login">
            <Button variant="outline" size="sm">
              Sign In
            </Button>
          </Link>
        </div>
      </header>

      <main className="relative z-10 flex-1 flex items-center justify-center px-4">
        <div className="text-center max-w-2xl mx-auto space-y-8">
          <div className="space-y-4">
            <h1 className="text-5xl md:text-6xl font-bold tracking-tight leading-tight">
              Digital{" "}
              <span className="bg-gradient-to-r from-primary to-chart-1 bg-clip-text text-transparent">
                Gurukul
              </span>
            </h1>
            <p className="text-xl text-muted-foreground max-w-lg mx-auto leading-relaxed">
              Bringing quality education to every corner of India, regardless
              of bandwidth.
            </p>
          </div>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link href="/login">
              <Button size="lg" className="text-base px-8 font-semibold">
                Get Started
              </Button>
            </Link>
          </div>

          <div className="grid grid-cols-3 gap-8 pt-12 max-w-md mx-auto">
            <FeatureStat label="Live Sessions" icon="📡" />
            <FeatureStat label="Offline Sync" icon="📱" />
            <FeatureStat label="Smart Quizzes" icon="🧠" />
          </div>
        </div>
      </main>

      <footer className="relative z-10 border-t border-border/30 py-6 text-center text-sm text-muted-foreground">
        © 2026 Digi-Kul. Built for India&apos;s future.
      </footer>
    </div>
  );
}

function FeatureStat({ label, icon }: { label: string; icon: string }) {
  return (
    <div className="text-center space-y-2">
      <div className="text-3xl">{icon}</div>
      <p className="text-sm font-medium text-muted-foreground">{label}</p>
    </div>
  );
}
