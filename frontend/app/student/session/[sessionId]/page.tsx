"use client";

import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import Peer from "simple-peer";
import { toast } from "sonner";
import { Hand, Headphones, LogOut, Volume2, VolumeX } from "lucide-react";
import { getToken, getUser } from "@/lib/auth";
import { getLecture } from "@/lib/api";
import { getRtcConfig } from "@/lib/webrtc";
import { useLiveSession } from "@/lib/useLiveSession";
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

type AudioState = "waiting" | "connecting" | "playing" | "blocked" | "failed";

export default function StudentSessionPage() {
  const params = useParams();
  const router = useRouter();
  const sessionId = params.sessionId as string;

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

  const peerRef = useRef<Peer.Instance | null>(null);
  const teacherIdRef = useRef<string | null>(null);
  const audioRef = useRef<HTMLAudioElement>(null);
  const [audioState, setAudioState] = useState<AudioState>("waiting");
  const [handUp, setHandUp] = useState(false);
  const [mutedByTeacher, setMutedByTeacher] = useState(false);

  const signalRef = useRef<ReturnType<typeof useLiveSession>["signal"] | null>(null);

  const destroyPeer = useCallback(() => {
    peerRef.current?.destroy();
    peerRef.current = null;
    if (audioRef.current) audioRef.current.srcObject = null;
  }, []);

  const acceptOffer = useCallback(
    (fromUserId: string, sdp: Peer.SignalData) => {
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
          .catch(() => setAudioState("blocked"));
      });
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
    },
    [destroyPeer]
  );

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
    if (!isClient) return;
    if (!token || !user) {
      router.replace("/login");
      return;
    }
    if (user.user_type === "teacher") router.replace(`/teacher/session/${sessionId}`);
    return () => destroyPeer();
  }, [isClient, token, user, sessionId, router, destroyPeer]);

  const connected = session.state === "connected";
  const elapsed = useElapsed(connected);
  const teacher = session.participants.find((p) => p.user_type === "teacher");
  const others = session.participants.filter((p) => p.user_type !== "teacher" && p.user_id !== user?.user_id);

  const toggleHand = () => {
    if (handUp) {
      setHandUp(false);
      return;
    }
    if (session.raiseHand()) {
      setHandUp(true);
      toast.success("Hand raised");
    }
  };

  const unblockAudio = () =>
    audioRef.current?.play().then(() => setAudioState("playing")).catch(() => setAudioState("blocked"));

  const leave = () => router.push("/dashboard/student");

  const audioLabel: Record<AudioState, string> = {
    playing: "Listening",
    connecting: "Connecting audio…",
    waiting: teacher ? "Waiting for audio…" : "Waiting for the teacher…",
    failed: "Audio failed — reload to retry",
    blocked: "Tap to enable audio",
  };

  if (!isClient) return null;

  return (
    <SessionShell
      header={
        <>
          <audio ref={audioRef} autoPlay playsInline />
          <div className="flex min-w-0 items-center gap-3">
            <ConnectionDot state={session.state} />
            <div className="min-w-0">
              <h1 className="truncate text-[15px] font-semibold sm:text-base">{lectureTitle}</h1>
              <div className="truncate text-xs text-muted-foreground">
                {session.statusText}
                {connected && ` · ${elapsed}`}
                {teacher && ` · ${teacher.user_name}`}
                {session.reconnectCount > 0 && ` · reconnected ×${session.reconnectCount}`}
              </div>
            </div>
          </div>
          <div className="ml-auto flex items-center gap-2">
            {session.isRecording && (
              <Pill tone="live">
                <span className="live-dot" /> REC
              </Pill>
            )}
            {mutedByTeacher && <Pill tone="warn">Muted by teacher</Pill>}
          </div>
        </>
      }
      stage={
        session.state === "error" ? (
          <StageMessage
            title="Couldn't join"
            body={session.statusText}
            action={<Link href="/dashboard/student" className="rounded-lg bg-ink px-4 py-2 text-sm font-semibold text-white">Back to dashboard</Link>}
          />
        ) : session.state === "ended" ? (
          <StageMessage title="Class has ended" body="Taking you back to your dashboard…" />
        ) : (
          <>
            <TileGrid count={1 + others.length}>
              <ParticipantTile
                name={teacher?.user_name ?? "Teacher"}
                role="teacher"
                highlight
                status={audioLabel[audioState]}
                statusTone={audioState === "playing" ? "ok" : audioState === "failed" ? "live" : "muted"}
                icon={audioState === "playing" ? <Volume2 className="size-3.5" /> : audioState === "failed" ? <VolumeX className="size-3.5" /> : <Headphones className="size-3.5" />}
              />
              {others.map((p) => (
                <ParticipantTile key={p.user_id} name={p.user_name} status={session.raisedHands.has(p.user_id) ? "Hand raised" : "In room"} statusTone={session.raisedHands.has(p.user_id) ? "warn" : "muted"} icon={session.raisedHands.has(p.user_id) ? <Hand className="size-3.5" /> : undefined} />
              ))}
            </TileGrid>
            {audioState === "blocked" && (
              <button type="button" onClick={unblockAudio} className="rounded-lg bg-ink px-5 py-2.5 text-sm font-semibold text-white">
                Enable audio
              </button>
            )}
          </>
        )
      }
      controls={
        <>
          <ControlButton onClick={toggleHand} disabled={!connected} active={handUp} title={handUp ? "Lower hand" : "Raise hand"}>
            <Hand />
            {handUp ? "Hand raised" : "Raise hand"}
          </ControlButton>
          {audioState === "blocked" && (
            <ControlButton onClick={unblockAudio} tone="primary" title="Enable audio">
              <Volume2 /> Enable audio
            </ControlButton>
          )}
          <ControlButton onClick={leave} tone="danger" title="Leave">
            <LogOut /> Leave
          </ControlButton>
        </>
      }
      sidebar={
        <>
          <ParticipantList participants={session.participants} raisedHands={session.raisedHands} selfId={user?.user_id} />
          <ChatPanel messages={session.chat} onSend={session.sendChat} disabled={!connected} />
        </>
      }
    />
  );
}
