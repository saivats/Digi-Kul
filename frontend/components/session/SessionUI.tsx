"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import { Hand, Send } from "lucide-react";
import { cn } from "@/lib/utils";
import type { ChatMsg, ConnectionState, Participant } from "@/lib/useLiveSession";

// ---------------------------------------------------------------------------
// Connection status
// ---------------------------------------------------------------------------
export function ConnectionDot({ state }: { state: ConnectionState }) {
  const cls =
    state === "connected"
      ? "bg-online shadow-[0_0_0_4px_rgba(5,150,105,0.2)]"
      : state === "reconnecting" || state === "handshaking" || state === "connecting"
        ? "bg-saffron animate-pulse"
        : "bg-live";
  return <span className={cn("inline-block size-2.5 shrink-0 rounded-full", cls)} aria-hidden />;
}

export function useElapsed(running: boolean) {
  const startRef = useRef<number | null>(null);
  const [text, setText] = useState("00:00");
  useEffect(() => {
    if (!running) return;
    if (startRef.current === null) startRef.current = Date.now();
    const id = setInterval(() => {
      const s = Math.floor((Date.now() - (startRef.current ?? Date.now())) / 1000);
      const h = Math.floor(s / 3600);
      const m = Math.floor((s % 3600) / 60);
      const sec = s % 60;
      setText(
        (h ? `${String(h).padStart(2, "0")}:` : "") +
          `${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`
      );
    }, 1000);
    return () => clearInterval(id);
  }, [running]);
  return text;
}

// ---------------------------------------------------------------------------
// Layout shell
// ---------------------------------------------------------------------------
export function SessionShell({
  header,
  stage,
  controls,
  sidebar,
}: {
  header: ReactNode;
  stage: ReactNode;
  controls: ReactNode;
  sidebar: ReactNode;
}) {
  return (
    <div className="dark flex h-dvh flex-col bg-background text-foreground">
      <header className="flex h-16 shrink-0 items-center gap-4 border-b border-border bg-card px-4 sm:px-6">
        {header}
      </header>
      <div className="flex min-h-0 flex-1 flex-col lg:flex-row">
        <div className="flex min-h-0 flex-1 flex-col">
          <div className="flex min-h-0 flex-1 flex-col items-center justify-center gap-5 overflow-y-auto p-4 sm:p-8">
            {stage}
          </div>
          <div className="flex h-[88px] shrink-0 items-center justify-center gap-3 border-t border-border bg-card px-4">
            {controls}
          </div>
        </div>
        <aside className="flex h-[42vh] shrink-0 flex-col border-t border-border bg-card lg:h-auto lg:w-[360px] lg:border-l lg:border-t-0">
          {sidebar}
        </aside>
      </div>
    </div>
  );
}

export function Pill({ tone, children }: { tone: "live" | "muted" | "ok" | "warn"; children: ReactNode }) {
  const cls = {
    live: "bg-live-soft text-[#fb7185]",
    muted: "bg-secondary text-muted-foreground",
    ok: "bg-online-soft text-[#34d399]",
    warn: "bg-scheduled-soft text-[#fbbf24]",
  }[tone];
  return (
    <span className={cn("inline-flex h-8 items-center gap-1.5 rounded-full px-3 text-xs font-bold tracking-wide", cls)}>
      {children}
    </span>
  );
}

// ---------------------------------------------------------------------------
// Participant tiles
// ---------------------------------------------------------------------------
function initials(name: string) {
  return (name || "?")
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

export function ParticipantTile({
  name,
  role,
  status,
  statusTone = "muted",
  highlight,
  icon,
}: {
  name: string;
  role?: string;
  status: string;
  statusTone?: "muted" | "ok" | "warn" | "live";
  highlight?: boolean;
  icon?: ReactNode;
}) {
  const toneCls = { muted: "text-muted-foreground", ok: "text-[#34d399]", warn: "text-[#fbbf24]", live: "text-[#fb7185]" }[statusTone];
  return (
    <div
      className={cn(
        "flex h-[220px] w-full flex-col items-center justify-center gap-3 rounded-2xl border bg-card sm:h-[280px]",
        highlight ? "border-2 border-ink" : "border-border"
      )}
    >
      <div className={cn("flex size-[72px] items-center justify-center rounded-full font-heading text-2xl font-bold sm:size-[84px] sm:text-[28px]", highlight ? "bg-ink text-white" : "bg-secondary text-foreground/80")}>
        {initials(name)}
      </div>
      <div className="font-heading text-base font-semibold">{name}{role === "teacher" && <span className="ml-2 text-[11px] font-bold tracking-wider text-[#a5b4fc]">HOST</span>}</div>
      <div className={cn("flex items-center gap-1.5 text-xs", toneCls)}>{icon}{status}</div>
    </div>
  );
}

export function TileGrid({ children, count }: { children: ReactNode; count: number }) {
  return (
    <div
      className={cn(
        "grid w-full max-w-[880px] gap-4",
        count <= 1 ? "grid-cols-1 max-w-[440px]" : count <= 4 ? "grid-cols-2" : "grid-cols-2 sm:grid-cols-3"
      )}
    >
      {children}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------
export function ControlButton({
  children,
  onClick,
  disabled,
  tone = "default",
  active,
  title,
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  tone?: "default" | "danger" | "primary";
  active?: boolean;
  title?: string;
}) {
  const cls =
    tone === "danger"
      ? "bg-live text-white hover:bg-live/90"
      : tone === "primary"
        ? "bg-ink text-white hover:bg-ink/90"
        : active
          ? "bg-scheduled-soft text-[#fbbf24]"
          : "bg-secondary text-foreground hover:bg-secondary/80";
  return (
    <button
      type="button"
      title={title}
      onClick={onClick}
      disabled={disabled}
      className={cn(
        "inline-flex h-12 items-center gap-2 rounded-xl px-4 text-sm font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-40 sm:px-[18px] [&_svg]:size-[18px]",
        cls
      )}
    >
      {children}
    </button>
  );
}

// ---------------------------------------------------------------------------
// Sidebar: participants + chat
// ---------------------------------------------------------------------------
export function ParticipantList({
  participants,
  raisedHands,
  selfId,
  onMute,
  onLowerHand,
}: {
  participants: Participant[];
  raisedHands: Map<string, string>;
  selfId?: string | null;
  onMute?: (id: string, name: string) => void;
  onLowerHand?: (id: string) => void;
}) {
  return (
    <>
      <div className="flex items-center justify-between border-b border-border px-[18px] py-3.5">
        <h2 className="text-[13px] font-semibold uppercase tracking-[0.06em] text-muted-foreground">Participants · {participants.length}</h2>
      </div>
      <ul className="max-h-[38%] shrink-0 overflow-y-auto">
        {participants.length === 0 && <li className="px-[18px] py-4 text-xs text-muted-foreground">No one else here yet.</li>}
        {participants.map((p) => {
          const hand = raisedHands.has(p.user_id);
          return (
            <li key={p.user_id} className="flex items-center gap-2.5 px-[18px] py-2.5">
              <span className={cn("flex size-8 shrink-0 items-center justify-center rounded-full text-xs font-bold", p.user_type === "teacher" ? "bg-ink text-white" : "bg-secondary text-foreground/80")}>
                {initials(p.user_name)}
              </span>
              <span className="min-w-0 flex-1 truncate text-sm font-medium">
                {p.user_name}{p.user_id === selfId && <span className="text-muted-foreground"> (you)</span>}
              </span>
              {hand && (
                <button type="button" title={onLowerHand ? "Lower hand" : "Hand raised"} onClick={() => onLowerHand?.(p.user_id)} className="inline-flex size-6 items-center justify-center rounded-full bg-scheduled-soft text-[#fbbf24]">
                  <Hand className="size-3.5" />
                </button>
              )}
              {p.user_type === "teacher" ? (
                <span className="text-[11px] font-bold tracking-wider text-[#a5b4fc]">HOST</span>
              ) : onMute ? (
                <button type="button" onClick={() => onMute(p.user_id, p.user_name)} className="text-xs font-semibold text-muted-foreground hover:text-foreground">
                  Mute
                </button>
              ) : null}
            </li>
          );
        })}
      </ul>
    </>
  );
}

export function ChatPanel({
  messages,
  onSend,
  disabled,
}: {
  messages: ChatMsg[];
  onSend: (text: string) => void;
  disabled?: boolean;
}) {
  const [input, setInput] = useState("");
  const endRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    endRef.current?.scrollIntoView({ block: "end" });
  }, [messages]);

  return (
    <>
      <div className="flex items-center justify-between border-y border-border px-[18px] py-3.5">
        <h2 className="text-[13px] font-semibold uppercase tracking-[0.06em] text-muted-foreground">Chat</h2>
      </div>
      <div className="flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto px-[18px] py-4" aria-live="polite">
        {messages.length === 0 && <div className="text-xs text-muted-foreground">Messages everyone in the room can see.</div>}
        {messages.map((m, i) => (
          <div key={i} className={cn("flex max-w-[85%] flex-col gap-1", m.mine ? "items-end self-end" : "self-start")}>
            <div className="text-[11px] font-semibold text-muted-foreground">
              {m.mine ? "You" : m.user_name}
              {m.timestamp && ` · ${new Date(m.timestamp).toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" })}`}
            </div>
            <div className={cn("rounded-xl px-3 py-2.5 text-sm leading-[1.45]", m.mine ? "rounded-br-[4px] bg-ink text-white" : "rounded-bl-[4px] bg-secondary")}>
              {m.message}
            </div>
          </div>
        ))}
        <div ref={endRef} />
      </div>
      <form
        className="flex gap-2 border-t border-border px-[18px] py-3.5"
        onSubmit={(e) => {
          e.preventDefault();
          const t = input.trim();
          if (!t) return;
          onSend(t);
          setInput("");
        }}
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Message everyone…"
          aria-label="Chat message"
          disabled={disabled}
          maxLength={2000}
          className="h-11 min-w-0 flex-1 rounded-[10px] border border-border bg-background px-3.5 text-sm outline-none placeholder:text-muted-foreground focus:ring-2 focus:ring-ring disabled:opacity-50"
        />
        <button type="submit" aria-label="Send" disabled={disabled || !input.trim()} className="inline-flex size-11 shrink-0 items-center justify-center rounded-[10px] bg-ink text-white transition-colors hover:bg-ink/90 disabled:opacity-40">
          <Send className="size-[18px]" />
        </button>
      </form>
    </>
  );
}

export function StageMessage({ title, body, action }: { title: string; body?: string; action?: ReactNode }) {
  return (
    <div className="flex max-w-sm flex-col items-center gap-3 text-center">
      <div className="font-heading text-lg font-semibold">{title}</div>
      {body && <div className="text-sm text-muted-foreground">{body}</div>}
      {action}
    </div>
  );
}
