import logging

import socketio

from app.database import get_supabase
from app.services import recording_service
from app.utils.security import decode_access_token

logger = logging.getLogger("digi-kul.socket")

sio = socketio.AsyncServer(async_mode="asgi", cors_allowed_origins="*")
sio_app = socketio.ASGIApp(sio)


class SessionStore:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._sessions: dict[str, dict] = {}
            cls._instance._participants: dict[str, list[dict]] = {}
            cls._instance._user_sockets: dict[str, str] = {}
            cls._instance._whiteboard_strokes: dict[str, list[dict]] = {}
        return cls._instance

    def create_session(self, session_id: str, data: dict) -> None:
        self._sessions[session_id] = data

    def get_session(self, session_id: str) -> dict | None:
        return self._sessions.get(session_id)

    def remove_session(self, session_id: str) -> None:
        self._sessions.pop(session_id, None)
        self._participants.pop(session_id, None)
        self._whiteboard_strokes.pop(session_id, None)

    def list_sessions(self) -> list[str]:
        return list(self._sessions.keys())

    def add_participant(self, session_id: str, participant: dict) -> None:
        if session_id not in self._participants:
            self._participants[session_id] = []
        self._participants[session_id] = [
            p for p in self._participants[session_id] if p["user_id"] != participant["user_id"]
        ]
        self._participants[session_id].append(participant)

    def remove_participant(self, session_id: str, user_id: str) -> None:
        if session_id in self._participants:
            self._participants[session_id] = [
                p for p in self._participants[session_id] if p["user_id"] != user_id
            ]

    def get_participants(self, session_id: str) -> list[dict]:
        return self._participants.get(session_id, [])

    def map_user_socket(self, user_id: str, sid: str) -> None:
        self._user_sockets[user_id] = sid

    def unmap_user_socket(self, user_id: str) -> None:
        self._user_sockets.pop(user_id, None)

    def get_socket_for_user(self, user_id: str) -> str | None:
        return self._user_sockets.get(user_id)

    def get_user_for_socket(self, sid: str) -> str | None:
        for uid, s in self._user_sockets.items():
            if s == sid:
                return uid
        return None

    def add_whiteboard_stroke(self, session_id: str, stroke: dict) -> None:
        if session_id not in self._whiteboard_strokes:
            self._whiteboard_strokes[session_id] = []
        self._whiteboard_strokes[session_id].append(stroke)

    def get_whiteboard_strokes(self, session_id: str) -> list[dict]:
        return self._whiteboard_strokes.get(session_id, [])

    def clear_whiteboard(self, session_id: str) -> None:
        self._whiteboard_strokes[session_id] = []


session_store = SessionStore()


def _authenticate_socket(data: dict) -> dict | None:
    token = data.get("token")
    if not token:
        return None
    try:
        return decode_access_token(token)
    except Exception:
        return None


@sio.event
async def connect(sid, environ):
    logger.info("Socket connected: %s", sid)


@sio.event
async def disconnect(sid):
    user_id = session_store.get_user_for_socket(sid)
    if user_id:
        for sess_id in session_store.list_sessions():
            participant = next(
                (p for p in session_store.get_participants(sess_id) if p["user_id"] == user_id),
                None,
            )
            if participant:
                session_store.remove_participant(sess_id, user_id)
                await sio.emit(
                    "participant_left",
                    {"user_id": user_id, "user_name": participant.get("user_name", "")},
                    room=sess_id,
                )
        session_store.unmap_user_socket(user_id)
    logger.info("Socket disconnected: %s (user=%s)", sid, user_id)


@sio.event
async def authenticate(sid, data):
    user = _authenticate_socket(data)
    if not user:
        await sio.emit("auth_error", {"error": "Invalid token"}, to=sid)
        return
    session_store.map_user_socket(user["sub"], sid)
    await sio.emit("authenticated", {"user_id": user["sub"], "user_type": user.get("user_type")}, to=sid)


@sio.event
async def create_session(sid, data):
    user = _authenticate_socket(data)
    if not user:
        return
    session_id = data.get("session_id") or data.get("lecture_id")
    if not session_id:
        return

    session_store.create_session(session_id, {
        "teacher_id": user["sub"],
        "teacher_name": user.get("user_name", ""),
        "lecture_id": data.get("lecture_id"),
        "cohort_id": data.get("cohort_id"),
        "institution_id": user.get("institution_id"),
        "started_at": data.get("started_at"),
    })

    await sio.enter_room(sid, session_id)
    await sio.emit("session_created", {"session_id": session_id}, to=sid)
    logger.info("Session created: %s by teacher %s", session_id, user["sub"])


@sio.event
async def join_session(sid, data):
    user = _authenticate_socket(data)
    if not user:
        return
    session_id = data.get("session_id")
    if not session_id or not session_store.get_session(session_id):
        await sio.emit("session_error", {"error": "Session not found"}, to=sid)
        return

    participant = {
        "user_id": user["sub"],
        "user_name": user.get("user_name", ""),
        "user_type": user.get("user_type", ""),
        "sid": sid,
    }
    session_store.add_participant(session_id, participant)
    await sio.enter_room(sid, session_id)

    await sio.emit(
        "participant_joined",
        {"user_id": user["sub"], "user_name": user.get("user_name", ""), "user_type": user.get("user_type", "")},
        room=session_id,
        skip_sid=sid,
    )
    await sio.emit(
        "session_joined",
        {
            "session_id": session_id,
            "participants": session_store.get_participants(session_id),
            "whiteboard_strokes": session_store.get_whiteboard_strokes(session_id),
        },
        to=sid,
    )
    logger.info("User %s joined session %s", user["sub"], session_id)


@sio.event
async def leave_session(sid, data):
    user = _authenticate_socket(data)
    if not user:
        return
    session_id = data.get("session_id")
    if session_id:
        session_store.remove_participant(session_id, user["sub"])
        await sio.leave_room(sid, session_id)
        await sio.emit(
            "participant_left",
            {"user_id": user["sub"], "user_name": user.get("user_name", "")},
            room=session_id,
        )


@sio.event
async def end_session(sid, data):
    user = _authenticate_socket(data)
    if not user:
        return
    session_id = data.get("session_id")
    session = session_store.get_session(session_id)
    if not session or session["teacher_id"] != user["sub"]:
        return

    await sio.emit("session_ended", {"session_id": session_id}, room=session_id)
    session_store.remove_session(session_id)
    logger.info("Session ended: %s", session_id)


@sio.event
async def webrtc_offer(sid, data):
    target_sid = session_store.get_socket_for_user(data.get("target_user_id", ""))
    if target_sid:
        await sio.emit("webrtc_offer", {
            "from_user_id": data.get("from_user_id"),
            "sdp": data.get("sdp"),
        }, to=target_sid)


@sio.event
async def webrtc_answer(sid, data):
    target_sid = session_store.get_socket_for_user(data.get("target_user_id", ""))
    if target_sid:
        await sio.emit("webrtc_answer", {
            "from_user_id": data.get("from_user_id"),
            "sdp": data.get("sdp"),
        }, to=target_sid)


@sio.event
async def webrtc_ice_candidate(sid, data):
    target_sid = session_store.get_socket_for_user(data.get("target_user_id", ""))
    if target_sid:
        await sio.emit("webrtc_ice_candidate", {
            "from_user_id": data.get("from_user_id"),
            "candidate": data.get("candidate"),
        }, to=target_sid)


@sio.event
async def chat_message(sid, data):
    session_id = data.get("session_id")
    if not session_id:
        return
    await sio.emit("chat_message", {
        "user_id": data.get("user_id"),
        "user_name": data.get("user_name"),
        "message": data.get("message"),
        "timestamp": data.get("timestamp"),
    }, room=session_id, skip_sid=sid)


@sio.event
async def whiteboard_stroke(sid, data):
    session_id = data.get("session_id")
    if not session_id:
        return
    stroke = {
        "user_id": data.get("user_id"),
        "points": data.get("points"),
        "color": data.get("color"),
        "width": data.get("width"),
        "tool": data.get("tool"),
    }
    session_store.add_whiteboard_stroke(session_id, stroke)
    await sio.emit("whiteboard_stroke", stroke, room=session_id, skip_sid=sid)


@sio.event
async def whiteboard_clear(sid, data):
    session_id = data.get("session_id")
    if session_id:
        session_store.clear_whiteboard(session_id)
        await sio.emit("whiteboard_clear", {}, room=session_id, skip_sid=sid)


@sio.event
async def start_recording(sid, data):
    user = _authenticate_socket(data)
    if not user:
        return
    session_id = data.get("session_id")
    session = session_store.get_session(session_id)
    if not session:
        return

    recording = recording_service.create_recording(
        institution_id=session.get("institution_id", ""),
        cohort_id=session.get("cohort_id", ""),
        lecture_id=session.get("lecture_id", ""),
        teacher_id=user["sub"],
        session_id=session_id,
        title=data.get("title", f"Recording - {session_id}"),
    )
    await sio.emit("recording_started", {"recording_id": recording.get("id")}, room=session_id)


@sio.event
async def stop_recording(sid, data):
    await sio.emit("recording_stopped", {"session_id": data.get("session_id")}, room=data.get("session_id"))


@sio.event
async def poll_created(sid, data):
    session_id = data.get("session_id")
    if session_id:
        await sio.emit("poll_created", data, room=session_id, skip_sid=sid)


@sio.event
async def poll_response(sid, data):
    session_id = data.get("session_id")
    if session_id:
        await sio.emit("poll_response", data, room=session_id, skip_sid=sid)


@sio.event
async def hand_raised(sid, data):
    session_id = data.get("session_id")
    if session_id:
        await sio.emit("hand_raised", {
            "user_id": data.get("user_id"),
            "user_name": data.get("user_name"),
        }, room=session_id, skip_sid=sid)


@sio.event
async def mute_participant(sid, data):
    target_sid = session_store.get_socket_for_user(data.get("target_user_id", ""))
    if target_sid:
        await sio.emit("muted", {"muted_by": data.get("teacher_id")}, to=target_sid)
