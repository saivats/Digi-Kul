"""End-to-end live-session tests against a REAL 2-worker uvicorn + Redis.

Scenario requested: teacher creates a session, a student joins, the student
drops and reconnects (page-refresh style: a second socket authenticates as the
same user while the first is still open), and a WebRTC offer/answer
round-trips. Plus the security properties added alongside: ownership checks,
relay scoping, and chat rate limiting.
"""

from __future__ import annotations

import asyncio
import re
import uuid

import pytest

from tests.conftest import Client, make_token

pytestmark = pytest.mark.asyncio


def _ids():
    return {
        "session": f"lec-{uuid.uuid4().hex[:8]}",
        "teacher": f"t-{uuid.uuid4().hex[:6]}",
        "student": f"s-{uuid.uuid4().hex[:6]}",
        "outsider": f"o-{uuid.uuid4().hex[:6]}",
    }


async def _open_room(base: str, ids: dict) -> Client:
    teacher = await Client(base, make_token(ids["teacher"], "teacher", "Ms. Rao"), "teacher").connect()
    await teacher.emit("authenticate")
    auth = await teacher.expect("authenticated")
    assert auth["user_id"] == ids["teacher"] and auth["user_type"] == "teacher"
    await teacher.emit("create_session", {"session_id": ids["session"], "lecture_id": ids["session"]})
    assert (await teacher.expect("session_created"))["session_id"] == ids["session"]
    await teacher.emit("join_session", {"session_id": ids["session"]})
    joined = await teacher.expect("session_joined")
    assert [p["user_id"] for p in joined["participants"]] == [ids["teacher"]]
    assert "sid" not in joined["participants"][0], "socket ids must not leak to clients"
    return teacher


async def _join_as(base: str, ids: dict, who: str, name: str, label: str) -> Client:
    c = await Client(base, make_token(ids[who], "student", name), label).connect()
    await c.emit("authenticate")
    await c.expect("authenticated")
    await c.emit("join_session", {"session_id": ids["session"]})
    return c


async def test_teacher_student_reconnect_and_webrtc_roundtrip(multiworker_server):
    base, _log = multiworker_server
    ids = _ids()
    teacher = await _open_room(base, ids)

    # --- student joins ----------------------------------------------------
    student = await _join_as(base, ids, "student", "Asha", "student#1")
    joined = await student.expect("session_joined")
    assert {p["user_id"] for p in joined["participants"]} == {ids["teacher"], ids["student"]}
    evt = await teacher.expect("participant_joined")
    assert evt["user_id"] == ids["student"] and evt["user_type"] == "student"

    # --- student "refreshes": new socket, same user, old one still open ----
    student2 = await _join_as(base, ids, "student", "Asha", "student#2")
    joined2 = await student2.expect("session_joined")
    assert {p["user_id"] for p in joined2["participants"]} == {ids["teacher"], ids["student"]}
    # Teacher sees exactly one leave (stale socket torn down) + one join.
    left = await teacher.expect("participant_left")
    assert left["user_id"] == ids["student"]
    rejoined = await teacher.expect("participant_joined")
    assert rejoined["user_id"] == ids["student"]
    # ...and the stale socket was kicked by the server.
    for _ in range(40):
        if not student.connected:
            break
        await asyncio.sleep(0.1)
    assert not student.connected, "stale socket should have been disconnected"
    # Participant list is exactly two entries — no ghost from the old socket.
    await student2.emit("leave_session", {"session_id": ids["session"]})
    await teacher.expect("participant_left")
    await student2.emit("join_session", {"session_id": ids["session"]})
    snapshot = await student2.expect("session_joined")
    assert sorted(p["user_id"] for p in snapshot["participants"]) == sorted([ids["teacher"], ids["student"]])
    await teacher.expect("participant_joined")

    # --- WebRTC offer / answer / ICE round trip ---------------------------
    offer_sdp = {"type": "offer", "sdp": "v=0 fake-offer"}
    await teacher.emit("webrtc_offer", {"target_user_id": ids["student"], "sdp": offer_sdp})
    got_offer = await student2.expect("webrtc_offer")
    assert got_offer == {"from_user_id": ids["teacher"], "sdp": offer_sdp}

    answer_sdp = {"type": "answer", "sdp": "v=0 fake-answer"}
    await student2.emit("webrtc_answer", {"target_user_id": ids["teacher"], "sdp": answer_sdp})
    got_answer = await teacher.expect("webrtc_answer")
    assert got_answer == {"from_user_id": ids["student"], "sdp": answer_sdp}

    cand = {"candidate": "candidate:1 1 udp 2113937151 10.0.0.1 5000 typ host"}
    await student2.emit("webrtc_ice_candidate", {"target_user_id": ids["teacher"], "candidate": cand})
    assert (await teacher.expect("webrtc_ice_candidate"))["candidate"] == cand

    # from_user_id is taken from the authenticated identity, not the payload.
    await student2.emit("webrtc_answer", {"target_user_id": ids["teacher"], "sdp": answer_sdp, "from_user_id": "spoofed"})
    assert (await teacher.expect("webrtc_answer"))["from_user_id"] == ids["student"]

    # --- chat both ways, hand raise ---------------------------------------
    await student2.emit("chat_message", {"session_id": ids["session"], "message": "hello?", "timestamp": "t1"})
    msg = await teacher.expect("chat_message")
    assert msg["message"] == "hello?" and msg["user_id"] == ids["student"] and msg["user_name"] == "Asha"
    await teacher.emit("chat_message", {"session_id": ids["session"], "message": "hi Asha", "timestamp": "t2"})
    assert (await student2.expect("chat_message"))["message"] == "hi Asha"
    await student2.emit("hand_raised", {"session_id": ids["session"]})
    assert (await teacher.expect("hand_raised"))["user_id"] == ids["student"]

    # --- teacher mutes student (owner-only, target must be in room) --------
    await teacher.emit("mute_participant", {"session_id": ids["session"], "target_user_id": ids["student"]})
    assert (await student2.expect("muted"))["muted_by"] == ids["teacher"]

    # --- end session: everyone told, room gone ----------------------------
    await teacher.emit("end_session", {"session_id": ids["session"]})
    assert (await student2.expect("session_ended"))["session_id"] == ids["session"]
    assert (await teacher.expect("session_ended"))["session_id"] == ids["session"]
    late = await Client(base, make_token("late-1", "student", "Late"), "late").connect()
    await late.emit("authenticate")
    await late.expect("authenticated")
    await late.emit("join_session", {"session_id": ids["session"]})
    err = await late.expect("session_error")
    assert err == {"action": "join_session", "error": "Session not found"}

    for c in (teacher, student, student2, late):
        await c.close()


async def test_owner_only_controls_are_enforced(multiworker_server):
    base, _ = multiworker_server
    ids = _ids()
    teacher = await _open_room(base, ids)
    student = await _join_as(base, ids, "student", "Asha", "student")
    await student.expect("session_joined")
    await teacher.expect("participant_joined")

    for action, extra in [
        ("start_recording", {}),
        ("stop_recording", {}),
        ("mute_participant", {"target_user_id": ids["teacher"]}),
        ("end_session", {}),
    ]:
        await student.emit(action, {"session_id": ids["session"], **extra})
        err = await student.expect("session_error")
        assert err["action"] == action, err
        assert "owner" in err["error"].lower(), err
    # Teacher was never muted, nothing was recorded, session still up.
    await teacher.expect_none("muted")
    await teacher.expect_none("recording_started")
    await teacher.expect_none("session_ended")

    # A second teacher cannot hijack the room by "creating" it.
    hijacker = await Client(base, make_token("t-evil", "teacher", "Evil"), "hijacker").connect()
    await hijacker.emit("authenticate")
    await hijacker.expect("authenticated")
    await hijacker.emit("create_session", {"session_id": ids["session"]})
    err = await hijacker.expect("session_error")
    assert err["action"] == "create_session" and "another teacher" in err["error"]

    # Unauthenticated socket (never called authenticate, no token) gets nowhere.
    anon = Client(base, "", "anon")
    await anon.sio.connect(base, transports=["websocket"])
    await anon.sio.emit("mute_participant", {"session_id": ids["session"], "target_user_id": ids["student"]})
    err = await anon.expect("session_error")
    assert err["error"] == "Not authenticated"
    await student.expect_none("muted")

    for c in (teacher, student, hijacker, anon):
        await c.close()


async def test_webrtc_relay_only_between_sockets_in_same_session(multiworker_server):
    base, _ = multiworker_server
    ids = _ids()
    teacher = await _open_room(base, ids)
    student = await _join_as(base, ids, "student", "Asha", "student")
    await student.expect("session_joined")
    await teacher.expect("participant_joined")

    # Outsider is authenticated but in a different (own) session.
    other = _ids()
    outsider = await Client(base, make_token(ids["outsider"], "teacher", "Outsider"), "outsider").connect()
    await outsider.emit("authenticate")
    await outsider.expect("authenticated")
    await outsider.emit("create_session", {"session_id": other["session"]})
    await outsider.expect("session_created")
    await outsider.emit("join_session", {"session_id": other["session"]})
    await outsider.expect("session_joined")

    for event, key in [("webrtc_offer", "sdp"), ("webrtc_answer", "sdp"), ("webrtc_ice_candidate", "candidate")]:
        await outsider.emit(event, {"target_user_id": ids["student"], key: {"x": 1}})
        err = await outsider.expect("session_error")
        assert err == {"action": event, "error": "Target is not in your session"}
        await student.expect_none(event)

    # Target that is not connected at all.
    await teacher.emit("webrtc_offer", {"target_user_id": "nobody", "sdp": {}})
    assert (await teacher.expect("session_error"))["error"] == "Target is not connected"

    # Chat / strokes from a socket that hasn't joined the room are dropped.
    await outsider.emit("chat_message", {"session_id": ids["session"], "message": "spam"})
    await outsider.emit("whiteboard_stroke", {"session_id": ids["session"], "points": [[0, 0]]})
    await teacher.expect_none("chat_message")
    await teacher.expect_none("whiteboard_stroke")

    for c in (teacher, student, outsider):
        await c.close()


async def test_chat_rate_limit_per_connection(multiworker_server):
    base, _ = multiworker_server
    ids = _ids()
    teacher = await _open_room(base, ids)
    student = await _join_as(base, ids, "student", "Asha", "student")
    await student.expect("session_joined")
    await teacher.expect("participant_joined")

    # Server started with SOCKET_CHAT_BURST=5, SOCKET_CHAT_RATE=2/s.
    for i in range(20):
        await student.emit("chat_message", {"session_id": ids["session"], "message": f"m{i}"})
    limited = await student.expect("rate_limited")
    assert limited["event"] == "chat_message"
    await asyncio.sleep(0.5)
    delivered = teacher.drain("chat_message")
    assert 5 <= len(delivered) <= 7, f"expected ~burst(5) messages through, got {len(delivered)}"

    # A different connection has its own bucket.
    await teacher.emit("chat_message", {"session_id": ids["session"], "message": "teacher ok"})
    assert (await student.expect("chat_message"))["message"] == "teacher ok"

    await teacher.close()
    await student.close()


async def test_events_were_served_by_multiple_worker_processes(multiworker_server):
    """Sanity check that the previous tests really spanned >1 process — i.e.
    the Redis store + AsyncRedisManager are what made them pass."""
    _, log_path = multiworker_server
    text = log_path.read_text()
    pids = set(re.findall(r"\[pid (\d+)\] digi-kul\.socket: Socket connected", text))
    print(f"\nworker pids that accepted sockets: {sorted(pids)}")
    assert len(pids) >= 2, f"expected sockets on >=2 workers, log:\n{text[-3000:]}"
