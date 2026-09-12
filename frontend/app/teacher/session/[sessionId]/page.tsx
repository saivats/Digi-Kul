"use client";

import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import Peer from "simple-peer";
import { toast } from "sonner";
import { Circle, Hand, Mic, MicOff, PhoneOff, Square } from "lucide-react";
import { getToken, getUser } from "@/lib/auth";
import { getLecture } from "@/lib/api";
import { getRtcConfig, hasTurnConfigured } from "@/lib/webrtc";
import { useLiveSession, type Participant } from "@/lib/useLiveSession";
import {
  ChatPanel,
  ConnectionDot,
  ControlButton,
  ParticipantList,
  ParticipantTile,
  Pill,
  SessionShell,
  StageMessage,
  TileGrid,
  useElapsed,
} from "@/components/session/SessionUI";

export default function TeacherSessionPage() {
  const params = useParams();
  const router = useRouter();
  const sessionId = params.sessionId as string;

  // Read auth once — getUser() returns a new object per call, and using it
  // as an effect dependency re-created the socket on every render.
  // localStorage-backed auth only exists in the browser; render nothing on
  // the server so SSR markup never disagrees with the client (hydration).
  const isClient = useSyncExternalStore(() => () => {}, () => true, () => false);
  const user = useMemo(() => (isClient ? getUser() : null), [isClient]);
  const token = useMemo(() => (isClient ? getToken() : null), [isClient]);

  const lectureQuery = useQuery({
    queryKey: ["lecture", sessionId],
    queryFn: () => getLecture(sessionId),
    enabled: !!token && !!sessionId,
    retry: 1,
  });
  const lectureTitle: string = lectureQuery.data?.data?.title ?? "Live session";

  const localStreamRef = useRef<MediaStream | null>(null);
  const peersRef = useRef<Map<string, Peer.Instance>>(new Map());
  const [micState, setMicState] = useState<"pending" | "ready" | "unavailable">("pending");
  const [isMuted, setIsMuted] = useState(false);
  const [ending, setEnding] = useState(false);
  const [recTarget, setRecTarget] = useState<boolean | null>(null);
  const [connectedPeers, setConnectedPeers] = useState<Set<string>>(new Set());

  const destroyPeer = useCallback((userId: string) => {
    const p = peersRef.current.get(userId);
    if (p) {
      p.destroy();
      peersRef.current.delete(userId);
    }
    setConnectedPeers((prev) => {
      if (!prev.has(userId)) return prev;
      const n = new Set(prev);
      n.delete(userId);
      return n;
    });
  }, []);

  const signalRef = useRef<ReturnType<typeof useLiveSession>["signal"] | null>(null);

  const createPeerForStudent = useCallback(
    (studentUserId: string) => {
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
      peer.on("connect", () => setConnectedPeers((prev) => new Set(prev).add(studentUserId)));
      peer.on("error", (err) => console.error(`Peer error for ${studentUserId}:`, err));
      peer.on("close", () => {
        peersRef.current.delete(studentUserId);
        setConnectedPeers((prev) => {
          const n = new Set(prev);
          n.delete(studentUserId);
          return n;
        });
      });
      peersRef.current.set(studentUserId, peer);
    },
    [destroyPeer]
  );

  const session = useLiveSession({
    sessionId,
    token,
    userId: user?.user_id ?? null,
    userName: user?.user_name ?? "Teacher",
    role: "teacher",
    handlers: {
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

  // ---- mic ------------------------------------------------------------
  useEffect(() => {
    if (!isClient) return;
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
        session.participants.filter((p) => p.user_type !== "teacher").forEach((p) => createPeerForStudent(p.user_id));
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
  }, [isClient, token, user, sessionId, router]);

  const connected = session.state === "connected";
  const elapsed = useElapsed(connected);
  const turnOk = hasTurnConfigured();
  const students = session.participants.filter((p) => p.user_type !== "teacher");
  const recToggling = recTarget !== null && recTarget !== session.isRecording;

  const toggleMute = () => {
    const track = localStreamRef.current?.getAudioTracks()[0];
    if (!track) return;
    track.enabled = !track.enabled;
    setIsMuted(!track.enabled);
  };

  const toggleRecording = () => {
    const target = !session.isRecording;
    const ok = target ? session.startRecording(lectureTitle) : session.stopRecording();
    if (!ok) return;
    setRecTarget(target);
    setTimeout(() => setRecTarget(null), 8000);
  };

  const endSession = () => {
    if (!confirm("End this live session for everyone?")) return;
    setEnding(true);
    if (!session.endSession()) setEnding(false);
  };

  const micStatus =
    micState === "unavailable" ? "Text only — no mic" : isMuted ? "Muted" : micState === "ready" ? "Broadcasting" : "Requesting mic…";

  if (!isClient) return null;

  return (
    <SessionShell
      header={
        <>
          <div className="flex min-w-0 items-center gap-3">
            <ConnectionDot state={session.state} />
            <div className="min-w-0">
              <h1 className="truncate text-[15px] font-semibold sm:text-base">{lectureTitle}</h1>
              <div className="truncate text-xs text-muted-foreground">
                {session.statusText}
                {connected && ` · ${elapsed}`}
                {session.reconnectCount > 0 && ` · reconnected ×${session.reconnectCount}`}
                {` · ${students.length} student${students.length === 1 ? "" : "s"}`}
              </div>
            </div>
          </div>
          <div className="ml-auto flex items-center gap-2">
            {session.isRecording && (
              <Pill tone="live">
                <span className="live-dot" /> REC
              </Pill>
            )}
            <span className="hidden sm:inline-flex">
              <Pill tone={turnOk ? "ok" : "warn"}>{turnOk ? "TURN relay ready" : "STUN only"}</Pill>
            </span>
          </div>
        </>
      }
      stage={
        session.state === "error" ? (
          <StageMessage
            title="Couldn't open the room"
            body={session.statusText}
            action={<Link href="/dashboard/teacher/lectures" className="rounded-lg bg-ink px-4 py-2 text-sm font-semibold text-white">Back to lectures</Link>}
          />
        ) : (
          <>
            <TileGrid count={1 + students.length}>
              <ParticipantTile
                name={user?.user_name ?? "You"}
                role="teacher"
                highlight
                status={micStatus}
                statusTone={micState === "ready" && !isMuted ? "ok" : "muted"}
                icon={isMuted || micState !== "ready" ? <MicOff className="size-3.5" /> : <Mic className="size-3.5" />}
              />
              {students.map((s) => {
                const hand = session.raisedHands.has(s.user_id);
                const audio = connectedPeers.has(s.user_id);
                return (
                  <ParticipantTile
                    key={s.user_id}
                    name={s.user_name}
                    status={hand ? "Hand raised" : audio ? "Receiving audio" : micState === "ready" ? "Connecting audio…" : "In room"}
                    statusTone={hand ? "warn" : audio ? "ok" : "muted"}
                    icon={hand ? <Hand className="size-3.5" /> : undefined}
                  />
                );
              })}
            </TileGrid>
            {students.length === 0 && connected && (
              <div className="text-sm text-muted-foreground">Waiting for students — they join from their dashboard or the app.</div>
            )}
          </>
        )
      }
      controls={
        <>
          <ControlButton onClick={toggleMute} disabled={micState !== "ready"} active={isMuted} title={isMuted ? "Unmute" : "Mute"}>
            {isMuted ? <MicOff /> : <Mic />}
            <span className="hidden sm:inline">{isMuted ? "Unmute" : "Mute"}</span>
          </ControlButton>
          <ControlButton onClick={toggleRecording} disabled={!connected || recToggling} title={session.isRecording ? "Stop recording" : "Start recording"}>
            {session.isRecording ? <Square className="fill-current text-[#fb7185]" /> : <Circle className="text-[#fb7185]" />}
            <span className="hidden sm:inline">{recToggling ? "…" : session.isRecording ? "Stop recording" : "Record"}</span>
          </ControlButton>
          <ControlButton onClick={endSession} disabled={!connected || ending} tone="danger" title="End session">
            <PhoneOff />
            {ending ? "Ending…" : "End session"}
          </ControlButton>
        </>
      }
      sidebar={
        <>
          <ParticipantList
            participants={session.participants}
            raisedHands={session.raisedHands}
            selfId={user?.user_id}
            onLowerHand={session.lowerHand}
            onMute={(id, name) => {
              if (session.muteParticipant(id)) toast.success(`Muted ${name}`);
            }}
          />
          <ChatPanel messages={session.chat} onSend={session.sendChat} disabled={!connected} />
        </>
      }
    />
  );
}
