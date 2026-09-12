"""Live-session signalling server (Socket.IO).

State lives in Redis so any number of uvicorn workers / container replicas
can serve the same session, and python-socketio's AsyncRedisManager fans
every emit out to every process.

Event names are unchanged from the original in-process implementation so the
existing web client keeps working:
  client -> server: authenticate, create_session, join_session, leave_session,
                    end_session, webrtc_offer, webrtc_answer,
                    webrtc_ice_candidate, chat_message, whiteboard_stroke,
                    whiteboard_clear, start_recording, stop_recording,
                    poll_created, poll_response, hand_raised, mute_participant
  server -> client: authenticated, auth_error, session_created, session_joined,
                    session_error, session_ended, participant_joined,
                    participant_left, webrtc_offer, webrtc_answer,
                    webrtc_ice_candidate, chat_message, whiteboard_stroke,
                    whiteboard_clear, recording_started, recording_stopped,
                    poll_created, poll_response, hand_raised, muted,
                    rate_limited
"""

from __future__ import annotations

import asyncio
import json
import logging
import time
from typing import Any

import redis.asyncio as aioredis
import socketio

from app.config import get_settings
from app.services import attendance_service, recording_service
from app.utils.security import decode_access_token

logger = logging.getLogger("digi-kul.socket")
settings = get_settings()

# ---------------------------------------------------------------------------
# Socket.IO server
# ---------------------------------------------------------------------------
# Same origin list as the REST CORSMiddleware (settings.cors_origin_list).
# The Redis manager makes emits (rooms, per-sid, broadcast, remote disconnect)
# work across every worker that shares REDIS_URL.
sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins=settings.cors_origin_list,
    client_manager=socketio.AsyncRedisManager(settings.redis_url),
    ping_timeout=20,
    ping_interval=25,
)
# Served at the ASGI root by app.main so the path is `/socket.io/`, which is
# what socket.io-client defaults to and what nginx.conf proxies.
sio_app = socketio.ASGIApp(sio, socketio_path="socket.io")


# ---------------------------------------------------------------------------
# Redis-backed session store
# ---------------------------------------------------------------------------
class RedisSessionStore:
    """All live-session state, keyed under `dk:`.

    dk:sessions                 SET   of session ids
    dk:session:{sid}            HASH  session metadata (teacher_id, ...)
    dk:session:{sid}:parts      HASH  user_id -> participant JSON
    dk:session:{sid}:strokes    LIST  whiteboard stroke JSON
    dk:user_socket:{user_id}    STR   current socket id for a user
    dk:socket_user:{socket_id}  STR   user id for a socket
    dk:socket_sessions:{socket} SET   session ids this socket has joined
    """

    PREFIX = "dk:"
    MAX_STROKES = 5000

    def __init__(self, url: str, ttl_seconds: int) -> None:
        self._url = url
        self._ttl = ttl_seconds
        self._redis: aioredis.Redis | None = None

    # -- connection -------------------------------------------------------
    @property
    def redis(self) -> aioredis.Redis:
        if self._redis is None:
            self._redis = aioredis.from_url(self._url, decode_responses=True)
        return self._redis

    async def ping(self) -> bool:
        return bool(await self.redis.ping())

    async def close(self) -> None:
        if self._redis is not None:
            await self._redis.aclose()
            self._redis = None

    # -- keys -------------------------------------------------------------
    def _k(self, *parts: str) -> str:
        return self.PREFIX + ":".join(parts)

    # -- sessions ---------------------------------------------------------
    async def create_session(self, session_id: str, data: dict) -> None:
        """Create or refresh a session's metadata. Existing participants and
        strokes are preserved so a teacher refreshing the page doesn't wipe
        the room."""
        key = self._k("session", session_id)
        mapping = {k: ("" if v is None else str(v)) for k, v in data.items()}
        pipe = self.redis.pipeline()
        pipe.hset(key, mapping=mapping)
        pipe.sadd(self._k("sessions"), session_id)
        pipe.expire(key, self._ttl)
        pipe.expire(self._k("session", session_id, "parts"), self._ttl)
        pipe.expire(self._k("session", session_id, "strokes"), self._ttl)
        await pipe.execute()

    async def get_session(self, session_id: str | None) -> dict | None:
        if not session_id:
            return None
        data = await self.redis.hgetall(self._k("session", session_id))
        return data or None

    async def set_session_field(self, session_id: str, field: str, value: str) -> None:
        await self.redis.hset(self._k("session", session_id), field, value)

    async def remove_session(self, session_id: str) -> None:
        pipe = self.redis.pipeline()
        pipe.delete(self._k("session", session_id))
        pipe.delete(self._k("session", session_id, "parts"))
        pipe.delete(self._k("session", session_id, "strokes"))
        pipe.srem(self._k("sessions"), session_id)
        await pipe.execute()

    async def touch(self, session_id: str) -> None:
        pipe = self.redis.pipeline()
        for key in (
            self._k("session", session_id),
            self._k("session", session_id, "parts"),
            self._k("session", session_id, "strokes"),
        ):
            pipe.expire(key, self._ttl)
        await pipe.execute()

    # -- participants -----------------------------------------------------
    async def add_participant(self, session_id: str, participant: dict) -> None:
        await self.redis.hset(
            self._k("session", session_id, "parts"),
            participant["user_id"],
            json.dumps(participant),
        )
        await self.redis.sadd(self._k("socket_sessions", participant["sid"]), session_id)

    async def get_participant(self, session_id: str, user_id: str) -> dict | None:
        raw = await self.redis.hget(self._k("session", session_id, "parts"), user_id)
        return json.loads(raw) if raw else None

    async def remove_participant(self, session_id: str, user_id: str) -> None:
        await self.redis.hdel(self._k("session", session_id, "parts"), user_id)

    async def get_participants(self, session_id: str) -> list[dict]:
        raw = await self.redis.hgetall(self._k("session", session_id, "parts"))
        return [json.loads(v) for v in raw.values()]

    # -- socket <-> user mapping -----------------------------------------
    async def map_user_socket(self, user_id: str, sid: str) -> str | None:
        """Map user -> socket and return the previous socket id (if any)."""
        old = await self.redis.getset(self._k("user_socket", user_id), sid)
        await self.redis.set(self._k("socket_user", sid), user_id)
        if old and old != sid:
            await self.redis.delete(self._k("socket_user", old))
        return old if old != sid else None

    async def unmap_socket(self, sid: str) -> None:
        user_id = await self.redis.get(self._k("socket_user", sid))
        pipe = self.redis.pipeline()
        pipe.delete(self._k("socket_user", sid))
        pipe.delete(self._k("socket_sessions", sid))
        if user_id:
            # Only clear the user->socket link if it still points at *this*
            # socket; a newer connection may have replaced it.
            current = await self.redis.get(self._k("user_socket", user_id))
            if current == sid:
                pipe.delete(self._k("user_socket", user_id))
        await pipe.execute()

    async def get_socket_for_user(self, user_id: str) -> str | None:
        if not user_id:
            return None
        return await self.redis.get(self._k("user_socket", user_id))

    async def get_user_for_socket(self, sid: str) -> str | None:
        return await self.redis.get(self._k("socket_user", sid))

    async def get_sessions_for_socket(self, sid: str) -> set[str]:
        return set(await self.redis.smembers(self._k("socket_sessions", sid)))

    async def forget_socket_session(self, sid: str, session_id: str) -> None:
        await self.redis.srem(self._k("socket_sessions", sid), session_id)

    # -- whiteboard -------------------------------------------------------
    async def add_whiteboard_stroke(self, session_id: str, stroke: dict) -> None:
        key = self._k("session", session_id, "strokes")
        pipe = self.redis.pipeline()
        pipe.rpush(key, json.dumps(stroke))
        pipe.ltrim(key, -self.MAX_STROKES, -1)
        await pipe.execute()

    async def get_whiteboard_strokes(self, session_id: str) -> list[dict]:
        raw = await self.redis.lrange(self._k("session", session_id, "strokes"), 0, -1)
        return [json.loads(s) for s in raw]

    async def clear_whiteboard(self, session_id: str) -> None:
        await self.redis.delete(self._k("session", session_id, "strokes"))


session_store = RedisSessionStore(settings.redis_url, settings.session_ttl_seconds)


# ---------------------------------------------------------------------------
# Per-connection rate limiting (token bucket, in-process: a socket connection
# always lives on exactly one worker, so this does not need Redis).
# ---------------------------------------------------------------------------
class _TokenBucket:
    __slots__ = ("rate", "capacity", "tokens", "updated")

    def __init__(self, rate: float, burst: int) -> None:
        self.rate = rate
        self.capacity = float(burst)
        self.tokens = float(burst)
        self.updated = time.monotonic()

    def allow(self) -> bool:
        now = time.monotonic()
        self.tokens = min(self.capacity, self.tokens + (now - self.updated) * self.rate)
        self.updated = now
        if self.tokens >= 1.0:
            self.tokens -= 1.0
            return True
        return False


_RATE_LIMITS: dict[str, tuple[float, int]] = {
    "chat_message": (settings.socket_chat_rate, settings.socket_chat_burst),
    "whiteboard_stroke": (settings.socket_stroke_rate, settings.socket_stroke_burst),
}
_buckets: dict[str, dict[str, _TokenBucket]] = {}


async def _allow(sid: str, event: str) -> bool:
    rate, burst = _RATE_LIMITS[event]
    bucket = _buckets.setdefault(sid, {}).get(event)
    if bucket is None:
        bucket = _buckets[sid][event] = _TokenBucket(rate, burst)
    if bucket.allow():
        return True
    await sio.emit("rate_limited", {"event": event}, to=sid)
    return False


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _decode(data: dict | None) -> dict | None:
    token = (data or {}).get("token")
    if not token:
        return None
    try:
        return decode_access_token(token)
    except Exception:
        return None


def _identity_from_claims(claims: dict) -> dict:
    return {
        "user_id": claims["sub"],
        "user_name": claims.get("user_name", ""),
        "user_type": claims.get("user_type", ""),
        "institution_id": claims.get("institution_id", ""),
    }


async def _current_user(sid: str, data: dict | None = None) -> dict | None:
    """Identity for a socket: the session saved by `authenticate`, falling
    back to a token carried in the event payload."""
    saved = await sio.get_session(sid)
    if saved and saved.get("user_id"):
        return saved
    claims = _decode(data)
    if claims:
        ident = _identity_from_claims(claims)
        await sio.save_session(sid, ident)
        return ident
    return None


async def _error(sid: str, action: str, message: str) -> None:
    await sio.emit("session_error", {"action": action, "error": message}, to=sid)


async def _require_owner(sid: str, action: str, data: dict) -> tuple[dict, str, dict] | None:
    """Resolve (user, session_id, session) and enforce that the caller is the
    teacher who owns the session. Emits `session_error` and returns None
    otherwise."""
    user = await _current_user(sid, data)
    if not user:
        await _error(sid, action, "Not authenticated")
        return None
    session_id = data.get("session_id")
    session = await session_store.get_session(session_id)
    if not session:
        await _error(sid, action, "Session not found")
        return None
    if session.get("teacher_id") != user["user_id"]:
        await _error(sid, action, "Only the session owner can do that")
        return None
    return user, session_id, session


async def _record_attendance(kind: str, session: dict, session_id: str, user: dict) -> None:
    lecture_id = session.get("lecture_id") or session_id
    try:
        if kind == "join":
            await asyncio.to_thread(
                attendance_service.mark_joined,
                institution_id=user.get("institution_id") or session.get("institution_id") or "",
                lecture_id=lecture_id,
                student_id=user["user_id"],
            )
        else:
            await asyncio.to_thread(attendance_service.mark_left, lecture_id=lecture_id, student_id=user["user_id"])
    except Exception:
        logger.warning("attendance %s failed for %s in %s", kind, user.get("user_id"), session_id, exc_info=True)


def _public_participant(p: dict) -> dict:
    return {k: v for k, v in p.items() if k != "sid"}


async def _cleanup_socket(sid: str, *, notify: bool = True, user_id: str | None = None) -> None:
    """Remove a socket's participant entries from every session it joined and
    drop its user mapping. Safe to call for sockets that were already replaced
    by a newer connection for the same user (pass `user_id` in that case, since
    the socket->user mapping has already moved to the new socket)."""
    user_id = user_id or await session_store.get_user_for_socket(sid)
    for session_id in await session_store.get_sessions_for_socket(sid):
        if not user_id:
            continue
        participant = await session_store.get_participant(session_id, user_id)
        # Only remove the entry if it still belongs to *this* socket; a newer
        # socket for the same user may already have re-joined.
        if participant and participant.get("sid") == sid:
            await session_store.remove_participant(session_id, user_id)
            if notify:
                await sio.emit(
                    "participant_left",
                    {"user_id": user_id, "user_name": participant.get("user_name", "")},
                    room=session_id,
                )
            if participant.get("user_type") == "student":
                session = await session_store.get_session(session_id) or {}
                asyncio.create_task(_record_attendance("leave", session, session_id, {"user_id": user_id}))
    await session_store.unmap_socket(sid)
    _buckets.pop(sid, None)


# ---------------------------------------------------------------------------
# Connection lifecycle
# ---------------------------------------------------------------------------
@sio.event
async def connect(sid, environ, auth=None):
    # socket.io-client sends `auth: {token}` on the handshake; python-socketio
    # then calls connect(sid, environ, auth). The old 2-arg signature raised
    # TypeError and rejected every handshake from the web client.
    claims = _decode(auth) if isinstance(auth, dict) else None
    if claims and claims.get("sub"):
        # Pre-seed identity so events that arrive before an explicit
        # `authenticate` (or without a token in the payload) still work.
        await sio.save_session(sid, _identity_from_claims(claims))
    logger.info("Socket connected: %s", sid)


@sio.event
async def disconnect(sid):
    user_id = await session_store.get_user_for_socket(sid)
    await _cleanup_socket(sid, notify=True)
    logger.info("Socket disconnected: %s (user=%s)", sid, user_id)


@sio.event
async def authenticate(sid, data):
    claims = _decode(data)
    if not claims or not claims.get("sub"):
        await sio.emit("auth_error", {"error": "Invalid token"}, to=sid)
        return
    ident = _identity_from_claims(claims)
    await sio.save_session(sid, ident)

    old_sid = await session_store.map_user_socket(ident["user_id"], sid)
    if old_sid:
        # Same user connected again (page refresh / reconnect without a clean
        # disconnect). Tear the stale socket's participant entries down now
        # instead of waiting for its ping timeout, then kick it.
        logger.info("User %s re-authenticated; replacing socket %s -> %s", ident["user_id"], old_sid, sid)
        await _cleanup_socket(old_sid, notify=True, user_id=ident["user_id"])
        try:
            await sio.disconnect(old_sid)  # routed via Redis if it lives on another worker
        except Exception:  # pragma: no cover - best effort
            logger.debug("Could not disconnect stale socket %s", old_sid, exc_info=True)

    await sio.emit(
        "authenticated",
        {"user_id": ident["user_id"], "user_type": ident["user_type"]},
        to=sid,
    )


# ---------------------------------------------------------------------------
# Session lifecycle
# ---------------------------------------------------------------------------
@sio.event
async def create_session(sid, data):
    user = await _current_user(sid, data)
    if not user:
        await _error(sid, "create_session", "Not authenticated")
        return
    if user.get("user_type") != "teacher":
        await _error(sid, "create_session", "Only teachers can create sessions")
        return
    session_id = data.get("session_id") or data.get("lecture_id")
    if not session_id:
        await _error(sid, "create_session", "session_id is required")
        return

    existing = await session_store.get_session(session_id)
    if existing and existing.get("teacher_id") != user["user_id"]:
        await _error(sid, "create_session", "Session belongs to another teacher")
        return

    await session_store.create_session(session_id, {
        "teacher_id": user["user_id"],
        "teacher_name": user.get("user_name", ""),
        "lecture_id": data.get("lecture_id") or session_id,
        "cohort_id": data.get("cohort_id") or (existing or {}).get("cohort_id", ""),
        "institution_id": user.get("institution_id", ""),
        "started_at": data.get("started_at") or (existing or {}).get("started_at", ""),
        "recording_id": (existing or {}).get("recording_id", ""),
    })
    await sio.enter_room(sid, session_id)
    await sio.emit("session_created", {"session_id": session_id}, to=sid)
    logger.info("Session created: %s by teacher %s", session_id, user["user_id"])


@sio.event
async def join_session(sid, data):
    user = await _current_user(sid, data)
    if not user:
        await _error(sid, "join_session", "Not authenticated")
        return
    session_id = data.get("session_id")
    session = await session_store.get_session(session_id)
    if not session:
        await _error(sid, "join_session", "Session not found")
        return

    participant = {
        "user_id": user["user_id"],
        "user_name": user.get("user_name", ""),
        "user_type": user.get("user_type", ""),
        "sid": sid,
    }
    await session_store.add_participant(session_id, participant)
    await session_store.touch(session_id)
    await sio.enter_room(sid, session_id)
    if user.get("user_type") == "student":
        # Attendance = joined the live session. Supabase client is sync, so
        # keep it off the event loop and never let a DB hiccup break the join.
        asyncio.create_task(_record_attendance("join", session, session_id, user))

    await sio.emit(
        "participant_joined",
        _public_participant(participant),
        room=session_id,
        skip_sid=sid,
    )
    participants = [_public_participant(p) for p in await session_store.get_participants(session_id)]
    await sio.emit(
        "session_joined",
        {
            "session_id": session_id,
            "participants": participants,
            "whiteboard_strokes": await session_store.get_whiteboard_strokes(session_id),
            "recording_id": session.get("recording_id") or None,
            "is_recording": bool(session.get("recording_id")),
        },
        to=sid,
    )
    logger.info("User %s joined session %s", user["user_id"], session_id)


@sio.event
async def leave_session(sid, data):
    user = await _current_user(sid, data)
    if not user:
        return
    session_id = data.get("session_id")
    if not session_id:
        return
    participant = await session_store.get_participant(session_id, user["user_id"])
    if participant and participant.get("sid") == sid:
        await session_store.remove_participant(session_id, user["user_id"])
        await sio.emit(
            "participant_left",
            {"user_id": user["user_id"], "user_name": user.get("user_name", "")},
            room=session_id,
        )
        if user.get("user_type") == "student":
            session = await session_store.get_session(session_id) or {}
            asyncio.create_task(_record_attendance("leave", session, session_id, user))
    await session_store.forget_socket_session(sid, session_id)
    await sio.leave_room(sid, session_id)


@sio.event
async def end_session(sid, data):
    resolved = await _require_owner(sid, "end_session", data)
    if not resolved:
        return
    _user, session_id, session = resolved

    recording_id = session.get("recording_id")
    if recording_id:
        try:
            participants = [p["user_id"] for p in await session_store.get_participants(session_id)]
            recording_service.finalize_recording(recording_id, participants=participants)
        except Exception:
            logger.exception("Failed to finalize recording %s on end_session", recording_id)
        await sio.emit(
            "recording_stopped",
            {"session_id": session_id, "recording_id": recording_id},
            room=session_id,
        )

    await sio.emit("session_ended", {"session_id": session_id}, room=session_id)
    await session_store.remove_session(session_id)
    logger.info("Session ended: %s", session_id)


# ---------------------------------------------------------------------------
# WebRTC signalling relay — only between sockets that share a session
# ---------------------------------------------------------------------------
async def _relay(sid: str, event: str, data: dict, payload_key: str) -> None:
    sender = await _current_user(sid, data)
    if not sender:
        await _error(sid, event, "Not authenticated")
        return
    target_user_id = data.get("target_user_id", "")
    target_sid = await session_store.get_socket_for_user(target_user_id)
    if not target_sid:
        await _error(sid, event, "Target is not connected")
        return

    sender_sessions = await session_store.get_sessions_for_socket(sid)
    target_sessions = await session_store.get_sessions_for_socket(target_sid)
    if not (sender_sessions & target_sessions):
        await _error(sid, event, "Target is not in your session")
        logger.warning("Blocked %s relay from %s to %s (no shared session)", event, sender["user_id"], target_user_id)
        return

    await sio.emit(
        event,
        {"from_user_id": sender["user_id"], payload_key: data.get(payload_key)},
        to=target_sid,
    )


@sio.event
async def webrtc_offer(sid, data):
    await _relay(sid, "webrtc_offer", data, "sdp")


@sio.event
async def webrtc_answer(sid, data):
    await _relay(sid, "webrtc_answer", data, "sdp")


@sio.event
async def webrtc_ice_candidate(sid, data):
    await _relay(sid, "webrtc_ice_candidate", data, "candidate")


# ---------------------------------------------------------------------------
# Chat / whiteboard / polls / hands
# ---------------------------------------------------------------------------
async def _member_of(sid: str, session_id: str | None) -> bool:
    return bool(session_id) and session_id in await session_store.get_sessions_for_socket(sid)


@sio.event
async def chat_message(sid, data):
    session_id = data.get("session_id")
    if not await _member_of(sid, session_id):
        return
    if not await _allow(sid, "chat_message"):
        return
    user = await _current_user(sid, data)
    message = str(data.get("message") or "")[:2000]
    if not message.strip():
        return
    await sio.emit("chat_message", {
        "user_id": user["user_id"] if user else data.get("user_id"),
        "user_name": user.get("user_name") if user else data.get("user_name"),
        "message": message,
        "timestamp": data.get("timestamp"),
    }, room=session_id, skip_sid=sid)


@sio.event
async def whiteboard_stroke(sid, data):
    session_id = data.get("session_id")
    if not await _member_of(sid, session_id):
        return
    if not await _allow(sid, "whiteboard_stroke"):
        return
    user = await _current_user(sid, data)
    stroke = {
        "user_id": user["user_id"] if user else data.get("user_id"),
        "points": data.get("points"),
        "color": data.get("color"),
        "width": data.get("width"),
        "tool": data.get("tool"),
    }
    await session_store.add_whiteboard_stroke(session_id, stroke)
    await sio.emit("whiteboard_stroke", stroke, room=session_id, skip_sid=sid)


@sio.event
async def whiteboard_clear(sid, data):
    session_id = data.get("session_id")
    if not await _member_of(sid, session_id):
        return
    await session_store.clear_whiteboard(session_id)
    await sio.emit("whiteboard_clear", {}, room=session_id, skip_sid=sid)


@sio.event
async def poll_created(sid, data):
    session_id = data.get("session_id")
    if await _member_of(sid, session_id):
        await sio.emit("poll_created", data, room=session_id, skip_sid=sid)


@sio.event
async def poll_response(sid, data):
    session_id = data.get("session_id")
    if await _member_of(sid, session_id):
        await sio.emit("poll_response", data, room=session_id, skip_sid=sid)


@sio.event
async def hand_raised(sid, data):
    session_id = data.get("session_id")
    if not await _member_of(sid, session_id):
        return
    user = await _current_user(sid, data)
    await sio.emit("hand_raised", {
        "user_id": user["user_id"] if user else data.get("user_id"),
        "user_name": user.get("user_name") if user else data.get("user_name"),
    }, room=session_id, skip_sid=sid)


# ---------------------------------------------------------------------------
# Teacher-only controls
# ---------------------------------------------------------------------------
@sio.event
async def start_recording(sid, data):
    resolved = await _require_owner(sid, "start_recording", data)
    if not resolved:
        return
    user, session_id, session = resolved
    if session.get("recording_id"):
        await _error(sid, "start_recording", "Recording already in progress")
        return

    try:
        recording = recording_service.create_recording(
            institution_id=session.get("institution_id", ""),
            cohort_id=session.get("cohort_id", ""),
            lecture_id=session.get("lecture_id", ""),
            teacher_id=user["user_id"],
            session_id=session_id,
            title=data.get("title") or f"Recording - {session_id}",
        )
    except Exception as exc:
        logger.exception("create_recording failed for session %s", session_id)
        await _error(sid, "start_recording", f"Could not start recording: {exc}")
        return
    recording_id = recording.get("id")
    if not recording_id:
        await _error(sid, "start_recording", "Could not start recording")
        return

    await session_store.set_session_field(session_id, "recording_id", str(recording_id))
    await sio.emit(
        "recording_started",
        {"recording_id": recording_id, "session_id": session_id},
        room=session_id,
    )


@sio.event
async def stop_recording(sid, data):
    resolved = await _require_owner(sid, "stop_recording", data)
    if not resolved:
        return
    _user, session_id, session = resolved
    recording_id = session.get("recording_id")
    if not recording_id:
        await _error(sid, "stop_recording", "No recording in progress")
        return

    try:
        participants = [p["user_id"] for p in await session_store.get_participants(session_id)]
        finalized = recording_service.finalize_recording(recording_id, participants=participants)
    except Exception as exc:
        logger.exception("finalize_recording failed for %s", recording_id)
        await _error(sid, "stop_recording", f"Could not finalize recording: {exc}")
        return

    await session_store.set_session_field(session_id, "recording_id", "")
    await sio.emit(
        "recording_stopped",
        {
            "session_id": session_id,
            "recording_id": recording_id,
            "duration": (finalized or {}).get("duration"),
            "stopped_at": (finalized or {}).get("stopped_at"),
        },
        room=session_id,
    )


@sio.event
async def mute_participant(sid, data):
    resolved = await _require_owner(sid, "mute_participant", data)
    if not resolved:
        return
    user, session_id, _session = resolved
    target_user_id = data.get("target_user_id", "")
    target = await session_store.get_participant(session_id, target_user_id)
    if not target:
        await _error(sid, "mute_participant", "Target is not in this session")
        return
    await sio.emit("muted", {"muted_by": user["user_id"], "session_id": session_id}, to=target["sid"])
