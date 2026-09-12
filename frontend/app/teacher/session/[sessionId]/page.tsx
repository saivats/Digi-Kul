"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Peer from "simple-peer";
import { toast } from "sonner";
import { getToken, getUser } from "@/lib/auth";
import { getRtcConfig, hasTurnConfigured } from "@/lib/webrtc";
import { useLiveSession, type Participant } from "@/lib/useLiveSession";

export default function TeacherSessionPage() {
  const params = useParams();
  const router = useRouter();
  const sessionId = params.sessionId as string;

  // Read auth once. `getUser()` parses localStorage and returns a NEW object
  // every call — using it directly as an effect dependency re-created the
  // socket on every render (the old page did exactly that).
  const user = useMemo(() => getUser(), []);
  const token = useMemo(() => getToken(), []);

  const localStreamRef = useRef<MediaStream | null>(null);
  const peersRef = useRef<Map<string, Peer.Instance>>(new Map());
  const [micState, setMicState] = useState<"pending" | "ready" | "unavailable">("pending");
  const [isMuted, setIsMuted] = useState(false);
  const [chatInput, setChatInput] = useState("");
  const [ending, setEnding] = useState(false);
  // Target recording state we asked the server for; "pending" until the
  // server's recording_started/stopped confirms it (or a timeout clears it).
  const [recTarget, setRecTarget] = useState<boolean | null>(null);
  const chatEndRef = useRef<HTMLDivElement>(null);

  // ---- WebRTC: teacher is the initiator for every student ---------------
  const destroyPeer = useCallback((userId: string) => {
    const p = peersRef.current.get(userId);
    if (p) {
      p.destroy();
      peersRef.current.delete(userId);
    }
  }, []);

  const signalRef = useRef<ReturnType<typeof useLiveSession>["signal"] | null>(null);

  const createPeerForStudent = useCallback((studentUserId: string) => {
    const stream = localStreamRef.current;
    if (!stream) return;
    destroyPeer(studentUserId);
    const peer = new Peer({ initiator: true, trickle: true, stream, config: getRtcConfig() });
    peer.on("signal", (data) => {
      if ("type" in data && data.type === "offer") {
        signalRef.current?.("webrtc_offer", studentUserId, { sdp: data });
      } else if ("candidate" in data) {
        signalRef.current?.("webrtc_ice_candidate", studentUserId, { candidate: data });
      }
    });
    peer.on("error", (err) => console.error(`Peer error for ${studentUserId}:`, err));
    peer.on("close", () => peersRef.current.delete(studentUserId));
    peersRef.current.set(studentUserId, peer);
  }, [destroyPeer]);

  const session = useLiveSession({
    sessionId,
    token,
    userId: user?.user_id ?? null,
    userName: user?.user_name ?? "Teacher",
    role: "teacher",
    handlers: {
      // On (re)join, make sure every student already in the room has a peer.
      // After a teacher reconnect the old peers are dead, so rebuild them.
      onSessionJoined: (list: Participant[]) => {
        list.filter((p) => p.user_type !== "teacher").forEach((p) => createPeerForStudent(p.user_id));
      },
      onParticipantJoined: (p) => {
        if (p.user_type !== "teacher") createPeerForStudent(p.user_id);
      },
      onParticipantLeft: (userId) => destroyPeer(userId),
      onWebrtcAnswer: (from, sdp) => peersRef.current.get(from)?.signal(sdp as Peer.SignalData),
      onWebrtcIceCandidate: (from, cand) => peersRef.current.get(from)?.signal(cand as Peer.SignalData),
      onSessionEnded: () => {
        toast.success("Session ended");
        router.push("/dashboard/teacher/lectures");
      },
    },
  });
  useEffect(() => {
    signalRef.current = session.signal;
  }, [session.signal]);

  // ---- mic ---------------------------------------------------------------
  useEffect(() => {
    if (!token || !user) {
      router.replace("/login");
      return;
    }
    if (user.user_type !== "teacher") {
      router.replace(`/student/session/${sessionId}`);
      return;
    }
    let cancelled = false;
    navigator.mediaDevices
      .getUserMedia({ audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true }, video: false })
      .then((stream) => {
        if (cancelled) {
          stream.getTracks().forEach((t) => t.stop());
          return;
        }
        localStreamRef.current = stream;
        setMicState("ready");
        // Students who joined before the mic was granted need peers now.
        session.participants
          .filter((p) => p.user_type !== "teacher")
          .forEach((p) => createPeerForStudent(p.user_id));
      })
      .catch(() => {
        if (!cancelled) setMicState("unavailable");
      });
    const peers = peersRef.current;
    return () => {
      cancelled = true;
      peers.forEach((p) => p.destroy());
      peers.clear();
      localStreamRef.current?.getTracks().forEach((t) => t.stop());
      localStreamRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token, user, sessionId, router]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [session.chat]);

  const toggleMute = () => {
    const track = localStreamRef.current?.getAudioTracks()[0];
    if (!track) return;
    track.enabled = !track.enabled;
    setIsMuted(!track.enabled);
  };

  const recToggling = recTarget !== null && recTarget !== session.isRecording;

  const toggleRecording = () => {
    const target = !session.isRecording;
    const ok = target
      ? session.startRecording(`Session ${sessionId}`)
      : session.stopRecording();
    if (!ok) return;
    setRecTarget(target);
    // The server answers with recording_started/stopped (or session_error);
    // give up waiting after 8s so the button never sticks.
    setTimeout(() => setRecTarget(null), 8000);
  };

  const endSession = () => {
    if (!confirm("End this live session for everyone?")) return;
    setEnding(true);
    if (!session.endSession()) setEnding(false);
  };

  const submitChat = (e: React.FormEvent) => {
    e.preventDefault();
    session.sendChat(chatInput);
    setChatInput("");
  };

  const students = session.participants.filter((p) => p.user_type !== "teacher");
  const connected = session.state === "connected";
  const turnOk = hasTurnConfigured();

  return (
    <div className="flex h-screen bg-background text-foreground">
      <div className="flex flex-col flex-1">
        <header className="flex items-center justify-between border-b border-border px-6 py-3">
          <div className="flex items-center gap-3">
            <div className={`h-3 w-3 rounded-full ${connected ? "bg-green-500" : session.state === "reconnecting" ? "bg-yellow-500 animate-pulse" : "bg-red-500"}`} />
            <div>
              <h1 className="text-lg font-semibold">Live Session</h1>
              <p className="text-xs text-muted-foreground">
                {session.statusText}
                {session.reconnectCount > 0 && ` · reconnected ×${session.reconnectCount}`}
                {" · Mode: "}
                <span className="font-medium uppercase">{micState === "ready" ? "audio" : micState === "pending" ? "…" : "text"}</span>
                {!turnOk && " · STUN only (no TURN configured)"}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {session.isRecording && (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-red-600/10 px-3 py-1 text-xs font-semibold text-red-500">
                <span className="h-2 w-2 rounded-full bg-red-500 animate-pulse" /> REC
              </span>
            )}
            <button onClick={toggleMute} disabled={micState !== "ready"} className={`inline-flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50 ${isMuted ? "bg-red-500/10 text-red-500 hover:bg-red-500/20" : "bg-muted text-muted-foreground hover:bg-muted/80"}`}>
              {isMuted ? "🔇 Unmute" : "🎤 Mute"}
            </button>
            <button onClick={toggleRecording} disabled={!connected || recToggling} className={`inline-flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50 ${session.isRecording ? "bg-red-600 text-white hover:bg-red-700" : "bg-muted text-muted-foreground hover:bg-muted/80"}`}>
              {recToggling ? "…" : session.isRecording ? "⏹ Stop Rec" : "⏺ Record"}
            </button>
            <button onClick={endSession} disabled={!connected || ending} className="inline-flex items-center gap-1.5 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-red-700 disabled:opacity-50">
              {ending ? "Ending…" : "✕ End Session"}
            </button>
          </div>
        </header>

        <div className="flex flex-1 overflow-hidden">
          <main className="flex flex-1 flex-col items-center justify-center p-8">
            {session.state === "error" ? (
              <div className="text-center space-y-3">
                <p className="text-lg font-semibold">Could not join</p>
                <p className="text-sm text-muted-foreground">{session.statusText}</p>
                <button onClick={() => router.push("/dashboard/teacher/lectures")} className="rounded-md bg-primary px-4 py-2 text-sm text-primary-foreground">Back to lectures</button>
              </div>
            ) : (
              <>
                <div className="relative flex h-48 w-48 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500/20 to-purple-500/20 ring-2 ring-indigo-500/30">
                  <span className="text-6xl">🎙️</span>
                </div>
                <p className="mt-6 text-sm text-muted-foreground">
                  {micState === "unavailable" ? "Text-only mode — no mic access" : isMuted ? "Your microphone is muted" : micState === "ready" ? "Broadcasting audio…" : "Requesting microphone…"}
                </p>
                <p className="mt-1 text-xs text-muted-foreground/60">
                  {students.length} student{students.length !== 1 && "s"} connected
                </p>
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
                  <span className="text-sm truncate">{p.user_name}</span>
                  {session.raisedHands.has(p.user_id) && (
                    <button title="Lower hand" onClick={() => session.lowerHand(p.user_id)} className="text-base">✋</button>
                  )}
                  {p.user_type === "teacher" ? (
                    <span className="ml-auto text-[10px] font-medium uppercase tracking-wider text-indigo-400">Host</span>
                  ) : (
                    <button onClick={() => { if (session.muteParticipant(p.user_id)) toast.success(`Muted ${p.user_name}`); }} className="ml-auto text-[11px] text-muted-foreground hover:text-foreground" title="Mute this student">
                      Mute
                    </button>
                  )}
                </li>
              ))}
              {session.participants.length === 0 && (
                <li className="px-4 py-6 text-center text-xs text-muted-foreground">No one has joined yet</li>
              )}
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
