"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { io, Socket } from "socket.io-client";
import Peer from "simple-peer";
import { getToken, getUser } from "@/lib/auth";

interface Participant {
  user_id: string;
  user_name: string;
  user_type: string;
}

interface ChatMsg {
  user_id: string;
  user_name: string;
  message: string;
  timestamp: string;
}

const SOCKET_URL =
  process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:8000";

export default function TeacherSessionPage() {
  const params = useParams();
  const router = useRouter();
  const sessionId = params.sessionId as string;
  const user = getUser();
  const token = getToken();

  const socketRef = useRef<Socket | null>(null);
  const localStreamRef = useRef<MediaStream | null>(null);
  const peersRef = useRef<Map<string, Peer.Instance>>(new Map());

  const [participants, setParticipants] = useState<Participant[]>([]);
  const [chatMessages, setChatMessages] = useState<ChatMsg[]>([]);
  const [chatInput, setChatInput] = useState("");
  const [isMuted, setIsMuted] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [sessionMode, setSessionMode] = useState<"audio" | "text">("audio");
  const [connectionStatus, setConnectionStatus] = useState("Connecting…");

  const chatEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = useCallback(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [chatMessages, scrollToBottom]);

  const createPeerForStudent = useCallback(
    (studentUserId: string, stream: MediaStream, socket: Socket) => {
      if (peersRef.current.has(studentUserId)) {
        peersRef.current.get(studentUserId)?.destroy();
      }

      const peer = new Peer({
        initiator: true,
        trickle: true,
        stream,
        config: {
          iceServers: [
            { urls: "stun:stun.l.google.com:19302" },
            { urls: "stun:stun1.l.google.com:19302" },
          ],
        },
      });

      peer.on("signal", (signalData) => {
        if (signalData.type === "offer") {
          socket.emit("webrtc_offer", {
            from_user_id: user?.user_id,
            target_user_id: studentUserId,
            sdp: signalData,
          });
        } else if ("candidate" in signalData) {
          socket.emit("webrtc_ice_candidate", {
            from_user_id: user?.user_id,
            target_user_id: studentUserId,
            candidate: signalData,
          });
        }
      });

      peer.on("error", (err) => {
        console.error(`Peer error for ${studentUserId}:`, err);
      });

      peersRef.current.set(studentUserId, peer);
      return peer;
    },
    [user?.user_id]
  );

  useEffect(() => {
    if (!token || !user || !sessionId) {
      router.push("/login");
      return;
    }

    let mounted = true;

    const initSession = async () => {
      let stream: MediaStream | null = null;
      try {
        stream = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
          },
          video: false,
        });
        localStreamRef.current = stream;
      } catch {
        setSessionMode("text");
        setConnectionStatus("Mic unavailable — text mode");
      }

      const socket = io(SOCKET_URL, {
        transports: ["websocket", "polling"],
        auth: { token },
      });

      socketRef.current = socket;

      socket.on("connect", () => {
        if (!mounted) return;
        setIsConnected(true);
        setConnectionStatus("Connected");

        socket.emit("authenticate", { token });
      });

      socket.on("authenticated", () => {
        socket.emit("create_session", {
          token,
          session_id: sessionId,
          lecture_id: sessionId,
        });
      });

      socket.on("session_created", () => {
        socket.emit("join_session", {
          token,
          session_id: sessionId,
        });
      });

      socket.on("session_joined", (data) => {
        if (!mounted) return;
        if (data.participants) {
          setParticipants(data.participants);
        }
      });

      socket.on("participant_joined", (data) => {
        if (!mounted) return;
        setParticipants((prev) => {
          const filtered = prev.filter((p) => p.user_id !== data.user_id);
          return [
            ...filtered,
            {
              user_id: data.user_id,
              user_name: data.user_name,
              user_type: data.user_type || "student",
            },
          ];
        });

        if (stream && data.user_type !== "teacher") {
          createPeerForStudent(data.user_id, stream, socket);
        }
      });

      socket.on("participant_left", (data) => {
        if (!mounted) return;
        setParticipants((prev) =>
          prev.filter((p) => p.user_id !== data.user_id)
        );
        const peer = peersRef.current.get(data.user_id);
        if (peer) {
          peer.destroy();
          peersRef.current.delete(data.user_id);
        }
      });

      socket.on("chat_message", (data) => {
        if (!mounted) return;
        setChatMessages((prev) => [...prev, data]);
      });

      socket.on("webrtc_answer", (data) => {
        const peer = peersRef.current.get(data.from_user_id);
        if (peer) {
          peer.signal(data.sdp);
        }
      });

      socket.on("webrtc_ice_candidate", (data) => {
        const peer = peersRef.current.get(data.from_user_id);
        if (peer) {
          peer.signal(data.candidate);
        }
      });

      socket.on("session_ended", () => {
        if (!mounted) return;
        setConnectionStatus("Session Ended");
        router.push("/dashboard/teacher");
      });

      socket.on("disconnect", () => {
        if (!mounted) return;
        setIsConnected(false);
        setConnectionStatus("Disconnected — reconnecting…");
      });

      socket.on("recording_started", () => {
        if (mounted) setIsRecording(true);
      });

      socket.on("recording_stopped", () => {
        if (mounted) setIsRecording(false);
      });
    };

    initSession();

    return () => {
      mounted = false;
      peersRef.current.forEach((peer) => peer.destroy());
      peersRef.current.clear();
      localStreamRef.current?.getTracks().forEach((t) => t.stop());
      if (socketRef.current) {
        socketRef.current.emit("leave_session", {
          token,
          session_id: sessionId,
        });
        socketRef.current.disconnect();
      }
    };
  }, [token, user, sessionId, router, createPeerForStudent]);

  const toggleMute = () => {
    const stream = localStreamRef.current;
    if (!stream) return;
    const audioTrack = stream.getAudioTracks()[0];
    if (audioTrack) {
      audioTrack.enabled = !audioTrack.enabled;
      setIsMuted(!audioTrack.enabled);
    }
  };

  const toggleRecording = () => {
    const socket = socketRef.current;
    if (!socket) return;
    if (isRecording) {
      socket.emit("stop_recording", { session_id: sessionId, token });
    } else {
      socket.emit("start_recording", {
        session_id: sessionId,
        token,
        title: `Session ${sessionId}`,
      });
    }
  };

  const endSession = () => {
    const socket = socketRef.current;
    if (!socket) return;
    socket.emit("end_session", { session_id: sessionId, token });
  };

  const sendChatMessage = () => {
    const trimmed = chatInput.trim();
    if (!trimmed || !socketRef.current) return;

    const msg: ChatMsg = {
      user_id: user?.user_id || "",
      user_name: user?.user_name || "Teacher",
      message: trimmed,
      timestamp: new Date().toISOString(),
    };

    socketRef.current.emit("chat_message", {
      session_id: sessionId,
      ...msg,
    });

    setChatMessages((prev) => [...prev, msg]);
    setChatInput("");
  };

  return (
    <div className="flex h-screen bg-background text-foreground">
      <div className="flex flex-col flex-1">
        <header className="flex items-center justify-between border-b border-border px-6 py-3">
          <div className="flex items-center gap-3">
            <div
              className={`h-3 w-3 rounded-full ${isConnected ? "bg-green-500 animate-pulse" : "bg-red-500"}`}
            />
            <div>
              <h1 className="text-lg font-semibold">Live Session</h1>
              <p className="text-xs text-muted-foreground">
                {connectionStatus} · Mode:{" "}
                <span className="font-medium uppercase">{sessionMode}</span>
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={toggleMute}
              className={`inline-flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
                isMuted
                  ? "bg-red-500/10 text-red-500 hover:bg-red-500/20"
                  : "bg-muted text-muted-foreground hover:bg-muted/80"
              }`}
            >
              {isMuted ? "🔇 Unmute" : "🎤 Mute"}
            </button>

            <button
              onClick={toggleRecording}
              className={`inline-flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
                isRecording
                  ? "bg-red-600 text-white hover:bg-red-700"
                  : "bg-muted text-muted-foreground hover:bg-muted/80"
              }`}
            >
              {isRecording ? "⏹ Stop Rec" : "⏺ Record"}
            </button>

            <button
              onClick={endSession}
              className="inline-flex items-center gap-1.5 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-red-700"
            >
              ✕ End Session
            </button>
          </div>
        </header>

        <div className="flex flex-1 overflow-hidden">
          <main className="flex flex-1 flex-col items-center justify-center p-8">
            <div className="relative flex h-48 w-48 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500/20 to-purple-500/20 ring-2 ring-indigo-500/30">
              {!isMuted && sessionMode === "audio" && (
                <>
                  <span className="absolute inset-0 animate-ping rounded-full bg-indigo-500/10" />
                  <span className="absolute inset-2 animate-pulse rounded-full bg-indigo-500/5" />
                </>
              )}
              <span className="text-6xl">🎙️</span>
            </div>
            <p className="mt-6 text-sm text-muted-foreground">
              {isMuted
                ? "Your microphone is muted"
                : sessionMode === "audio"
                  ? "Broadcasting audio…"
                  : "Text-only mode — no mic access"}
            </p>
            <p className="mt-1 text-xs text-muted-foreground/60">
              {participants.length} participant
              {participants.length !== 1 && "s"} connected
            </p>
          </main>

          <aside className="flex w-80 flex-col border-l border-border">
            <div className="border-b border-border px-4 py-3">
              <h2 className="text-sm font-semibold">
                Participants ({participants.length})
              </h2>
            </div>
            <ul className="flex-shrink-0 max-h-48 overflow-y-auto divide-y divide-border/50">
              {participants.map((p) => (
                <li
                  key={p.user_id}
                  className="flex items-center gap-2 px-4 py-2"
                >
                  <span className="flex h-7 w-7 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                    {p.user_name.charAt(0).toUpperCase()}
                  </span>
                  <span className="text-sm truncate">{p.user_name}</span>
                  {p.user_type === "teacher" && (
                    <span className="ml-auto text-[10px] font-medium uppercase tracking-wider text-indigo-400">
                      Host
                    </span>
                  )}
                </li>
              ))}
              {participants.length === 0 && (
                <li className="px-4 py-6 text-center text-xs text-muted-foreground">
                  No students have joined yet
                </li>
              )}
            </ul>

            <div className="border-t border-border px-4 py-3">
              <h2 className="text-sm font-semibold">Chat</h2>
            </div>
            <div className="flex-1 overflow-y-auto px-4 py-2 space-y-2">
              {chatMessages.map((msg, i) => (
                <div key={i} className="text-sm">
                  <span className="font-medium text-primary">
                    {msg.user_name}
                  </span>
                  <span className="ml-1.5 text-muted-foreground">
                    {msg.message}
                  </span>
                </div>
              ))}
              <div ref={chatEndRef} />
            </div>

            <div className="border-t border-border p-3">
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  sendChatMessage();
                }}
                className="flex gap-2"
              >
                <input
                  value={chatInput}
                  onChange={(e) => setChatInput(e.target.value)}
                  placeholder="Type a message…"
                  className="flex-1 rounded-md border border-border bg-background px-3 py-1.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                />
                <button
                  type="submit"
                  className="rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
                >
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
