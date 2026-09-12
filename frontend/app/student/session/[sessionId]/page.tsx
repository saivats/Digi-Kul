"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Peer from "simple-peer";
import { toast } from "sonner";
import { getToken, getUser } from "@/lib/auth";
import { getRtcConfig } from "@/lib/webrtc";
import { useLiveSession } from "@/lib/useLiveSession";

/**
 * Student side of a live session. The teacher initiates the WebRTC offer;
 * we answer it and play the teacher's audio. Chat + hand-raise go over the
 * signalling socket.
 */
export default function StudentSessionPage() {
  const params = useParams();
  const router = useRouter();
  const sessionId = params.sessionId as string;

  const user = useMemo(() => getUser(), []);
  const token = useMemo(() => getToken(), []);

  const peerRef = useRef<Peer.Instance | null>(null);
  const teacherIdRef = useRef<string | null>(null);
  const audioRef = useRef<HTMLAudioElement>(null);
  const [audioState, setAudioState] = useState<"waiting" | "connecting" | "playing" | "blocked" | "failed">("waiting");
  const [chatInput, setChatInput] = useState("");
  const [handUp, setHandUp] = useState(false);
  const [mutedByTeacher, setMutedByTeacher] = useState(false);
  const chatEndRef = useRef<HTMLDivElement>(null);

  const signalRef = useRef<ReturnType<typeof useLiveSession>["signal"] | null>(null);

  const destroyPeer = useCallback(() => {
    peerRef.current?.destroy();
    peerRef.current = null;
    if (audioRef.current) audioRef.current.srcObject = null;
  }, []);

  const acceptOffer = useCallback((fromUserId: string, sdp: Peer.SignalData) => {
    // A fresh offer means the teacher (re)started their side — replace any
    // existing peer rather than trying to renegotiate.
    destroyPeer();
    teacherIdRef.current = fromUserId;
    setAudioState("connecting");
    const peer = new Peer({ initiator: false, trickle: true, config: getRtcConfig() });
    peer.on("signal", (data) => {
      if ("type" in data && data.type === "answer") {
        signalRef.current?.("webrtc_answer", fromUserId, { sdp: data });
      } else if ("candidate" in data) {
        signalRef.current?.("webrtc_ice_candidate", fromUserId, { candidate: data });
      }
    });
    peer.on("stream", (stream) => {
      const el = audioRef.current;
      if (!el) return;
      el.srcObject = stream;
      el.play()
        .then(() => setAudioState("playing"))
        .catch(() => setAudioState("blocked")); // autoplay policy — needs a tap
    });
    peer.on("connect", () => setAudioState((s) => (s === "connecting" ? "playing" : s)));
    peer.on("error", (err) => {
      console.error("Peer error:", err);
      setAudioState("failed");
    });
    peer.on("close", () => {
      if (peerRef.current === peer) {
        peerRef.current = null;
        setAudioState("waiting");
      }
    });
    peer.signal(sdp);
    peerRef.current = peer;
  }, [destroyPeer]);

  const session = useLiveSession({
    sessionId,
    token,
    userId: user?.user_id ?? null,
    userName: user?.user_name ?? "Student",
    role: "student",
    handlers: {
      onWebrtcOffer: (from, sdp) => acceptOffer(from, sdp as Peer.SignalData),
      onWebrtcIceCandidate: (from, cand) => {
        if (from === teacherIdRef.current) peerRef.current?.signal(cand as Peer.SignalData);
      },
      onParticipantLeft: (userId) => {
        if (userId === teacherIdRef.current) {
          destroyPeer();
          setAudioState("waiting");
        }
      },
      onMuted: () => {
        setMutedByTeacher(true);
        toast.info("The teacher muted you.");
      },
      onSessionEnded: () => {
        destroyPeer();
        toast.info("The teacher ended the session.");
        setTimeout(() => router.push("/dashboard/student"), 1500);
      },
    },
  });
  useEffect(() => {
    signalRef.current = session.signal;
  }, [session.signal]);

  useEffect(() => {
    if (!token || !user) {
      router.replace("/login");
      return;
    }
    if (user.user_type === "teacher") {
      router.replace(`/teacher/session/${sessionId}`);
    }
    return () => destroyPeer();
  }, [token, user, sessionId, router, destroyPeer]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [session.chat]);

  const submitChat = (e: React.FormEvent) => {
    e.preventDefault();
    session.sendChat(chatInput);
    setChatInput("");
  };

  const toggleHand = () => {
    if (handUp) {
      setHandUp(false);
      return;
    }
    if (session.raiseHand()) setHandUp(true);
  };

  const unblockAudio = () => {
    audioRef.current?.play().then(() => setAudioState("playing")).catch(() => setAudioState("blocked"));
  };

  const connected = session.state === "connected";
  const teacher = session.participants.find((p) => p.user_type === "teacher");

  return (
    <div className="flex h-screen bg-background text-foreground">
      <audio ref={audioRef} autoPlay playsInline />
      <div className="flex flex-col flex-1">
        <header className="flex items-center justify-between border-b border-border px-6 py-3">
          <div className="flex items-center gap-3">
            <div className={`h-3 w-3 rounded-full ${connected ? "bg-green-500" : session.state === "reconnecting" ? "bg-yellow-500 animate-pulse" : "bg-red-500"}`} />
            <div>
              <h1 className="text-lg font-semibold">Live Session</h1>
              <p className="text-xs text-muted-foreground">
                {session.statusText}
                {session.reconnectCount > 0 && ` · reconnected ×${session.reconnectCount}`}
                {teacher && ` · Host: ${teacher.user_name}`}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {session.isRecording && (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-red-600/10 px-3 py-1 text-xs font-semibold text-red-500">
                <span className="h-2 w-2 rounded-full bg-red-500 animate-pulse" /> Recording
              </span>
            )}
            <button onClick={toggleHand} disabled={!connected} className={`inline-flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50 ${handUp ? "bg-yellow-500/20 text-yellow-500" : "bg-muted text-muted-foreground hover:bg-muted/80"}`}>
              ✋ {handUp ? "Hand raised" : "Raise hand"}
            </button>
            <button onClick={() => router.push("/dashboard/student")} className="inline-flex items-center gap-1.5 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-red-700">
              Leave
            </button>
          </div>
        </header>

        <div className="flex flex-1 overflow-hidden">
          <main className="flex flex-1 flex-col items-center justify-center p-8">
            {session.state === "error" ? (
              <div className="text-center space-y-3">
                <p className="text-lg font-semibold">Could not join</p>
                <p className="text-sm text-muted-foreground">{session.statusText}</p>
                <button onClick={() => router.push("/dashboard/student")} className="rounded-md bg-primary px-4 py-2 text-sm text-primary-foreground">Back to dashboard</button>
              </div>
            ) : session.state === "ended" ? (
              <div className="text-center space-y-2">
                <p className="text-lg font-semibold">Session ended</p>
                <p className="text-sm text-muted-foreground">Returning to your dashboard…</p>
              </div>
            ) : (
              <>
                <div className="relative flex h-48 w-48 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500/20 to-purple-500/20 ring-2 ring-indigo-500/30">
                  <span className="text-6xl">{audioState === "playing" ? "🔊" : "🎧"}</span>
                </div>
                <p className="mt-6 text-sm text-muted-foreground">
                  {audioState === "playing" && "Listening to the teacher"}
                  {audioState === "connecting" && "Connecting audio…"}
                  {audioState === "waiting" && (teacher ? "Waiting for the teacher's audio…" : "Waiting for the teacher to join…")}
                  {audioState === "failed" && "Audio connection failed — try reloading"}
                  {audioState === "blocked" && "Tap to enable audio"}
                </p>
                {audioState === "blocked" && (
                  <button onClick={unblockAudio} className="mt-3 rounded-md bg-primary px-4 py-2 text-sm text-primary-foreground">🔊 Enable audio</button>
                )}
                {mutedByTeacher && <p className="mt-2 text-xs text-yellow-500">You were muted by the teacher</p>}
              </>
            )}
          </main>

          <aside className="flex w-80 flex-col border-l border-border">
            <div className="border-b border-border px-4 py-3">
              <h2 className="text-sm font-semibold">Participants ({session.participants.length})</h2>
            </div>
            <ul className="flex-shrink-0 max-h-56 overflow-y-auto divide-y divide-border/50">
              {session.participants.map((p) => (
                <li key={p.user_id} className="flex items-center gap-2 px-4 py-2">
                  <span className="flex h-7 w-7 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                    {(p.user_name || "?").charAt(0).toUpperCase()}
                  </span>
                  <span className="text-sm truncate">{p.user_id === user?.user_id ? `${p.user_name} (you)` : p.user_name}</span>
                  {session.raisedHands.has(p.user_id) && <span>✋</span>}
                  {p.user_type === "teacher" && <span className="ml-auto text-[10px] font-medium uppercase tracking-wider text-indigo-400">Host</span>}
                </li>
              ))}
            </ul>

            <div className="border-t border-border px-4 py-3">
              <h2 className="text-sm font-semibold">Chat</h2>
            </div>
            <div className="flex-1 overflow-y-auto px-4 py-2 space-y-2">
              {session.chat.map((msg, i) => (
                <div key={i} className="text-sm">
                  <span className="font-medium text-primary">{msg.mine ? "You" : msg.user_name}</span>
                  <span className="ml-1.5 text-muted-foreground">{msg.message}</span>
                </div>
              ))}
              <div ref={chatEndRef} />
            </div>

            <div className="border-t border-border p-3">
              <form onSubmit={submitChat} className="flex gap-2">
                <input value={chatInput} onChange={(e) => setChatInput(e.target.value)} placeholder="Type a message…" disabled={!connected} className="flex-1 rounded-md border border-border bg-background px-3 py-1.5 text-sm outline-none focus:ring-1 focus:ring-primary disabled:opacity-50" />
                <button type="submit" disabled={!connected || !chatInput.trim()} className="rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-50">
                  Send
                </button>
              </form>
            </div>
          </aside>
        </div>
      </div>
    </div>
  );
}
