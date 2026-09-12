import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Logo } from "@/components/app/Logo";

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <header className="border-b border-border bg-card">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6">
          <Logo />
          <Button variant="outline" size="sm" nativeButton={false} render={<Link href="/login" />}>Sign in</Button>
        </div>
      </header>
      <main className="flex flex-1 items-center px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl items-center gap-12 lg:grid-cols-[1.2fr_1fr]">
          <div className="flex flex-col gap-6">
            <div className="eyebrow">Digital Gurukul</div>
            <h1 className="max-w-2xl text-4xl font-bold leading-[1.1] sm:text-5xl">
              Live classes that work on the connection you actually have.
            </h1>
            <p className="max-w-xl text-lg leading-relaxed text-muted-foreground">
              Audio-first live sessions, materials that sync for offline use, and quizzes that grade themselves — built for India&apos;s classrooms, on any phone.
            </p>
            <div className="flex flex-wrap gap-3">
              <Button size="lg" nativeButton={false} render={<Link href="/login" />}>Get started</Button>
            </div>
          </div>
          <div className="grid gap-3">
            {[
              ["Audio-first live sessions", "Teachers broadcast; students listen on ~24 kbps and chat or raise a hand."],
              ["Offline by design", "Materials and quizzes cache on the device and sync when the network returns."],
              ["Attendance that takes itself", "Joining the live room marks the student present — no roll call."],
            ].map(([t, d]) => (
              <div key={t} className="panel flex flex-col gap-1 p-5">
                <div className="font-heading font-semibold">{t}</div>
                <div className="text-sm text-muted-foreground">{d}</div>
              </div>
            ))}
          </div>
        </div>
      </main>
      <footer className="border-t border-border py-6 text-center text-sm text-muted-foreground">© 2026 Digi-Kul</footer>
    </div>
  );
}
