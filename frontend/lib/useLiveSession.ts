"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { io, type Socket } from "socket.io-client";
import { toast } from "sonner";
import { SOCKET_PATH, SOCKET_URL, checkPublicUrls } from "./env";

export interface Participant {
  user_id: string;
  user_name: string;
  user_type: string;
}

export interface ChatMsg {
  user_id: string;
  user_name: string;
  message: string;
  timestamp: string;
  mine?: boolean;
}

export type ConnectionState =
  | "connecting" // first connection attempt
  | "handshaking" // socket up, running authenticate -> join
  | "connected" // in the room
  | "reconnecting" // lost the socket; socket.io is retrying
  | "ended" // teacher ended the session
  | "error"; // unrecoverable (bad token, session not found, gave up)

export interface SessionEventHandlers {
  onSessionJoined?: (participants: Participant[]) => void;
  onParticipantJoined?: (p: Participant) => void;
  onParticipantLeft?: (userId: string) => void;
  onWebrtcOffer?: (fromUserId: string, sdp: unknown) => void;
  onWebrtcAnswer?: (fromUserId: string, sdp: unknown) => void;
  onWebrtcIceCandidate?: (fromUserId: string, candidate: unknown) => void;
  onMuted?: (mutedBy: string) => void;
  onSessionEnded?: () => void;
}

interface Options {
  sessionId: string;
  token: string | null;
  userId: string | null;
  userName: string;
  role: "teacher" | "student";
  handlers: SessionEventHandlers;
}

/**
 * Owns the Socket.IO connection for a live session.
 *
 * Reconnection: socket.io-client auto-reconnects (reconnection: true, no
 * attempt cap). Every `connect` — first or subsequent — re-runs the full
 * authenticate -> (create_session ->) join_session handshake, so a dropped
 * connection heals itself without a page refresh. The server tears down the
 * stale socket's participant entry when it sees the same user re-authenticate.
 */
export function useLiveSession({
  sessionId,
  token,
  userId,
  userName,
  role,
  handlers,
}: Options) {
  const socketRef = useRef<Socket | null>(null);
  const handlersRef = useRef(handlers);
  useEffect(() => {
    handlersRef.current = handlers;
  });

  const [state, setState] = useState<ConnectionState>("connecting");
  const [statusText, setStatusText] = useState("Connecting…");
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [chat, setChat] = useState<ChatMsg[]>([]);
  const [isRecording, setIsRecording] = useState(false);
  const [recordingId, setRecordingId] = useState<string | null>(null);
  const [raisedHands, setRaisedHands] = useState<Map<string, string>>(new Map());
  const [reconnectCount, setReconnectCount] = useState(0);

  useEffect(() => {
    if (!token || !userId || !sessionId) return;
    checkPublicUrls();

    let mounted = true;
    let everConnected = false;

    const socket = io(SOCKET_URL, {
      path: SOCKET_PATH,
      transports: ["websocket", "polling"],
      auth: { token },
      reconnection: true,
      reconnectionAttempts: Infinity,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 10_000,
      randomizationFactor: 0.5,
      timeout: 20_000,
    });
    socketRef.current = socket;

    // ---- handshake -------------------------------------------------------
    socket.on("connect", () => {
      if (!mounted) return;
      if (everConnected) setReconnectCount((n) => n + 1);
      everConnected = true;
      setState("handshaking");
      setStatusText("Authenticating…");
      socket.emit("authenticate", { token });
    });

    socket.on("authenticated", () => {
      if (!mounted) return;
      if (role === "teacher") {
        setStatusText("Opening room…");
        socket.emit("create_session", { token, session_id: sessionId, lecture_id: sessionId });
      } else {
        setStatusText("Joining room…");
        socket.emit("join_session", { token, session_id: sessionId });
      }
    });

    socket.on("session_created", () => {
      if (!mounted) return;
      socket.emit("join_session", { token, session_id: sessionId });
    });

    socket.on("session_joined", (data: { participants?: Participant[]; is_recording?: boolean; recording_id?: string | null }) => {
      if (!mounted) return;
      const list = (data.participants ?? []).map((p) => ({
        user_id: p.user_id,
        user_name: p.user_name,
        user_type: p.user_type,
      }));
      setParticipants(list);
      setIsRecording(!!data.is_recording);
      setRecordingId(data.recording_id ?? null);
      setState("connected");
      setStatusText("Connected");
      handlersRef.current.onSessionJoined?.(list);
    });

    socket.on("auth_error", (data: { error?: string }) => {
      if (!mounted) return;
      setState("error");
      setStatusText(data?.error || "Authentication failed");
      toast.error("Session authentication failed — please sign in again.");
      socket.disconnect();
    });

    socket.on("session_error", (data: { action?: string; error?: string }) => {
      if (!mounted) return;
      const msg = data?.error || "Session error";
      if (data?.action === "join_session" || data?.action === "create_session") {
        setState("error");
        setStatusText(
          msg === "Session not found" ? "This session is not live yet." : msg
        );
        socket.disconnect();
        return;
      }
      toast.error(msg);
    });

    socket.on("rate_limited", (data: { event?: string }) => {
      if (!mounted) return;
      if (data?.event === "chat_message") toast.warning("You're sending messages too fast.");
    });

    // ---- room events -----------------------------------------------------
    socket.on("participant_joined", (p: Participant) => {
      if (!mounted) return;
      setParticipants((prev) => [
        ...prev.filter((x) => x.user_id !== p.user_id),
        { user_id: p.user_id, user_name: p.user_name, user_type: p.user_type || "student" },
      ]);
      handlersRef.current.onParticipantJoined?.(p);
    });

    socket.on("participant_left", (data: { user_id: string }) => {
      if (!mounted) return;
      setParticipants((prev) => prev.filter((x) => x.user_id !== data.user_id));
      setRaisedHands((prev) => {
        if (!prev.has(data.user_id)) return prev;
        const next = new Map(prev);
        next.delete(data.user_id);
        return next;
      });
      handlersRef.current.onParticipantLeft?.(data.user_id);
    });

    socket.on("chat_message", (m: ChatMsg) => {
      if (!mounted) return;
      setChat((prev) => [...prev, { ...m, mine: false }]);
    });

    socket.on("hand_raised", (data: { user_id: string; user_name: string }) => {
      if (!mounted) return;
      setRaisedHands((prev) => new Map(prev).set(data.user_id, data.user_name));
      if (role === "teacher") toast(`${data.user_name} raised a hand`);
    });

    socket.on("recording_started", (data: { recording_id?: string }) => {
      if (!mounted) return;
      setIsRecording(true);
      setRecordingId(data?.recording_id ?? null);
    });

    socket.on("recording_stopped", () => {
      if (!mounted) return;
      setIsRecording(false);
      setRecordingId(null);
    });

    socket.on("muted", (data: { muted_by: string }) => {
      if (!mounted) return;
      handlersRef.current.onMuted?.(data.muted_by);
    });

    socket.on("session_ended", () => {
      if (!mounted) return;
      setState("ended");
      setStatusText("Session ended");
      handlersRef.current.onSessionEnded?.();
      socket.disconnect();
    });

    // ---- WebRTC signalling ----------------------------------------------
    socket.on("webrtc_offer", (d: { from_user_id: string; sdp: unknown }) =>
      handlersRef.current.onWebrtcOffer?.(d.from_user_id, d.sdp)
    );
    socket.on("webrtc_answer", (d: { from_user_id: string; sdp: unknown }) =>
      handlersRef.current.onWebrtcAnswer?.(d.from_user_id, d.sdp)
    );
    socket.on("webrtc_ice_candidate", (d: { from_user_id: string; candidate: unknown }) =>
      handlersRef.current.onWebrtcIceCandidate?.(d.from_user_id, d.candidate)
    );

    // ---- transport -------------------------------------------------------
    socket.on("disconnect", (reason) => {
      if (!mounted) return;
      // `io client disconnect` = we called disconnect() ourselves (ended/error).
      if (reason === "io client disconnect") return;
      setState("reconnecting");
      setStatusText("Connection lost — reconnecting…");
      // "io server disconnect" (server kicked us, e.g. replaced by a newer
      // tab) does not auto-reconnect; force it so a refresh isn't required.
      if (reason === "io server disconnect") socket.connect();
    });

    socket.io.on("reconnect_attempt", (attempt) => {
      if (!mounted) return;
      setStatusText(`Reconnecting… (attempt ${attempt})`);
    });

    socket.on("connect_error", (err) => {
      if (!mounted) return;
      if (!everConnected) setStatusText(`Cannot reach server: ${err.message}`);
    });

    return () => {
      mounted = false;
      socket.emit("leave_session", { token, session_id: sessionId });
      socket.removeAllListeners();
      socket.io.removeAllListeners();
      socket.disconnect();
      socketRef.current = null;
    };
    // handlers are read through a ref so they never retrigger this effect.
  }, [sessionId, token, userId, role]);

  // ---- emit helpers ------------------------------------------------------
  const emit = useCallback((event: string, payload: Record<string, unknown> = {}) => {
    const s = socketRef.current;
    if (!s || !s.connected) {
      toast.error("Not connected to the session.");
      return false;
    }
    s.emit(event, { token, session_id: sessionId, ...payload });
    return true;
  }, [token, sessionId]);

  const sendChat = useCallback((message: string) => {
    const trimmed = message.trim();
    if (!trimmed) return;
    const msg: ChatMsg = {
      user_id: userId ?? "",
      user_name: userName,
      message: trimmed,
      timestamp: new Date().toISOString(),
      mine: true,
    };
    if (emit("chat_message", { user_id: msg.user_id, user_name: msg.user_name, message: msg.message, timestamp: msg.timestamp })) {
      setChat((prev) => [...prev, msg]);
    }
  }, [emit, userId, userName]);

  const raiseHand = useCallback(() => emit("hand_raised", { user_id: userId, user_name: userName }), [emit, userId, userName]);
  const lowerHand = useCallback((id: string) => setRaisedHands((prev) => { const n = new Map(prev); n.delete(id); return n; }), []);
  const startRecording = useCallback((title?: string) => emit("start_recording", { title }), [emit]);
  const stopRecording = useCallback(() => emit("stop_recording"), [emit]);
  const endSession = useCallback(() => emit("end_session"), [emit]);
  const muteParticipant = useCallback((targetUserId: string) => emit("mute_participant", { target_user_id: targetUserId }), [emit]);

  const signal = useCallback(
    (event: "webrtc_offer" | "webrtc_answer" | "webrtc_ice_candidate", targetUserId: string, payload: Record<string, unknown>) => {
      const s = socketRef.current;
      if (!s || !s.connected) return;
      s.emit(event, { token, from_user_id: userId, target_user_id: targetUserId, ...payload });
    },
    [token, userId]
  );

  return {
    socketRef,
    state,
    statusText,
    participants,
    chat,
    isRecording,
    recordingId,
    raisedHands,
    reconnectCount,
    sendChat,
    raiseHand,
    lowerHand,
    startRecording,
    stopRecording,
    endSession,
    muteParticipant,
    signal,
  };
}
