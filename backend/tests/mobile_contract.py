"""Flutter-app contract walkthrough against a running backend.

Replays the student flow exactly as mobile/lib does it — same paths
(ApiConstants), same request bodies (ApiClient), same socket handshake
(SocketService) — and asserts every field the Dart DTOs require
(LectureDto, MaterialDto, QuizSetDto, QuizQuestionDto, QuizResultDto,
AttendanceDto). Run:

    BASE_URL=http://localhost:8000 python tests/mobile_contract.py

Exits non-zero on the first contract violation.
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
import urllib.error
import urllib.request

import socketio

BASE = os.environ.get("BASE_URL", "http://localhost:8000")
PASSWORD = os.environ.get("STUDENT_PASSWORD", "password123")
STUDENT = os.environ.get("STUDENT_EMAIL", "student@digikul.in")
TEACHER = os.environ.get("TEACHER_EMAIL", "teacher@digikul.in")
CHECKS: list[tuple[str, bool, str]] = []


def check(name: str, ok: bool, note: str = ""):
    CHECKS.append((name, ok, note))
    print(("PASS " if ok else "FAIL "), name, ("— " + note) if note else "")
    if not ok:
        print("\nContract violation — stopping.")
        sys.exit(1)


def req(method: str, path: str, body=None, token=None, raw=False):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(BASE + path, data=data, method=method)
    r.add_header("content-type", "application/json")
    r.add_header("accept", "application/json")
    if token:
        r.add_header("authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(r, timeout=20) as resp:
            content = resp.read()
            return resp.status, (content if raw else json.loads(content or b"null")), dict(resp.headers)
    except urllib.error.HTTPError as e:
        content = e.read()
        try:
            return e.code, json.loads(content), dict(e.headers)
        except Exception:
            return e.code, content, dict(e.headers)


def has(d: dict, *keys):
    missing = [k for k in keys if k not in d]
    return not missing, f"missing {missing}" if missing else ""


def main():
    # ---- ApiClient.login -------------------------------------------------
    st, body, _ = req("POST", "/api/auth/login", {"email": STUDENT, "password": PASSWORD, "user_type": "student"})
    check("POST /api/auth/login (student) 200", st == 200, str(body)[:120] if st != 200 else "")
    check("login: success flag present (AuthRepository checks data['success'])", body.get("success") is True)
    check("login: access_token + refresh_token + user_id/user_name/user_email/institution_id", has(body, "access_token", "refresh_token", "user_id", "user_name", "user_email", "institution_id")[0])
    tok, refresh = body["access_token"], body["refresh_token"]
    student_id = body["user_id"]

    # ---- DioClient refresh path ----------------------------------------
    st, body, _ = req("POST", "/api/auth/refresh", {"refresh_token": refresh})
    check("POST /api/auth/refresh -> new access_token", st == 200 and "access_token" in body)

    # ---- validate / logout ----------------------------------------------
    st, body, _ = req("GET", "/api/auth/validate-session", token=tok)
    check("GET /api/auth/validate-session valid=true", st == 200 and body.get("valid") is True)

    # ---- institutions (register screen) ----------------------------------
    st, body, _ = req("GET", "/api/public/institutions")
    check("GET /api/public/institutions -> {success,data:[...]}", st == 200 and isinstance(body.get("data"), list))

    # ---- profile / dashboard -------------------------------------------
    st, body, _ = req("GET", "/api/students/me", token=tok)
    check("GET /api/students/me", st == 200 and body["data"].get("id") == student_id)
    st, body, _ = req("GET", "/api/students/dashboard", token=tok)
    ok, note = has(body.get("data", {}), "profile", "cohorts", "live_lecture", "live_lectures", "upcoming_lectures", "recent_quiz_attempts", "attendance", "counts")
    check("GET /api/students/dashboard shape", st == 200 and ok, note)

    # ---- lectures (LectureDto) -------------------------------------------
    st, body, _ = req("GET", "/api/students/lectures", token=tok)
    lectures = body.get("data", [])
    check("GET /api/students/lectures -> list", st == 200 and isinstance(lectures, list) and lectures, f"{len(lectures)} lectures")
    for l in lectures:
        ok, note = has(l, "id", "title", "scheduled_time", "duration_minutes", "status", "cohort_id", "teacher_name", "session_id")
        check(f"LectureDto fields on '{l.get('title')}'", ok, note)
        break
    st, body, _ = req("GET", "/api/students/lectures/upcoming", token=tok)
    check("GET /api/students/lectures/upcoming", st == 200 and all(l["status"] == "scheduled" for l in body["data"]))

    # ---- materials (MaterialDto) + file open -------------------------------
    st, body, _ = req("GET", "/api/students/materials", token=tok)
    mats = body.get("data", [])
    check("GET /api/students/materials -> list", st == 200 and isinstance(mats, list) and mats, f"{len(mats)} materials")
    m = mats[0]
    ok, note = has(m, "id", "title", "file_name", "file_type", "file_size_bytes", "cohort_id", "uploaded_by", "uploaded_at", "download_url")
    check("MaterialDto fields", ok, note)
    check("download_url is API-relative (/api/materials/{id}/file)", m["download_url"].startswith("/api/materials/") and m["download_url"].endswith("/file"))
    st, content, headers = req("GET", m["download_url"], token=tok, raw=True)
    check("Dio.download(download_url) streams the file with bearer auth", st == 200 and len(content) == m["file_size_bytes"], f"{len(content)} bytes, {headers.get('content-disposition')}")
    st, _, _ = req("GET", m["download_url"])
    check("material file requires auth (401/403 without token)", st in (401, 403))

    # ---- attendance (AttendanceDto) -------------------------------------
    st, body, _ = req("GET", "/api/students/attendance", token=tok)
    check("GET /api/students/attendance -> {success,data,summary}", st == 200 and "summary" in body and isinstance(body["data"], list))
    if body["data"]:
        ok, note = has(body["data"][0], "id", "lecture_id", "lecture_title", "status", "lecture_date")
        check("AttendanceDto fields", ok, note)

    # ---- quizzes (QuizSetDto / QuizQuestionDto / QuizResultDto) ------------
    st, body, _ = req("GET", "/api/students/quizzes", token=tok)
    sets = body.get("data", [])
    check("GET /api/students/quizzes -> list", st == 200 and sets, f"{len(sets)} quiz sets")
    qs = sets[0]
    ok, note = has(qs, "id", "title", "description", "cohort_id", "question_count", "time_limit_seconds", "show_correct_answers", "available_from", "status")
    check("QuizSetDto fields", ok, note)
    st, body, _ = req("GET", f"/api/students/quizzes/{qs['id']}/questions", token=tok)
    qlist = body.get("data", [])
    check("GET /api/students/quizzes/{id}/questions", st == 200 and qlist)
    q = qlist[0]
    ok, note = has(q, "id", "quiz_set_id", "question", "question_type", "options", "order_index")
    check("QuizQuestionDto fields", ok, note)
    check("questions never leak correct_answer to students", all("correct_answer" not in x for x in qlist))
    check("options is List<String>", isinstance(q["options"], list) and all(isinstance(o, str) for o in q["options"]))

    st, body, _ = req("POST", "/api/students/quiz-attempts", {"quiz_set_id": qs["id"]}, token=tok)
    check("POST /api/students/quiz-attempts {quiz_set_id} -> attempt_id", st == 201 and body.get("attempt_id"))
    attempt_id = body["attempt_id"]
    st, body, _ = req("GET", f"/api/students/quiz-attempts/{attempt_id}/questions", token=tok)
    check("GET /api/students/quiz-attempts/{id}/questions", st == 200 and len(body["data"]) == len(qlist))

    # QuizRepository.saveAnswerLocally + submitAttempt: {answers: {qid: text}}
    answers = {x["id"]: x["options"][0] for x in qlist}
    st, body, _ = req("POST", f"/api/students/quiz-attempts/{attempt_id}/submit", {"answers": answers}, token=tok)
    res = body.get("data", {})
    ok, note = has(res, "attempt_id", "quiz_set_id", "total_questions", "correct_answers", "score_percentage", "time_taken_seconds", "review")
    check("POST submit -> QuizResultDto fields", st == 200 and ok, note)
    check("result.review entries have question_id/question/options/selected_answer/is_correct", all(has(r, "question_id", "question", "options", "selected_answer", "is_correct")[0] for r in res["review"]))
    score = res["score_percentage"]
    # offline queue replay: PendingQuizSubmission resubmits the same attempt
    st, body, _ = req("POST", f"/api/students/quiz-attempts/{attempt_id}/submit", {"answers": answers}, token=tok)
    check("offline replay: resubmitting a completed attempt is idempotent", st == 200 and body["data"]["score_percentage"] == score)
    st, body, _ = req("GET", f"/api/students/quiz-attempts/{attempt_id}/result", token=tok)
    check("GET /api/students/quiz-attempts/{id}/result", st == 200 and body["data"]["score_percentage"] == score)
    st, body, _ = req("POST", "/api/students/quiz-responses", {"attempt_id": attempt_id, "question_id": qlist[0]["id"], "response": "a"}, token=tok)
    check("POST /api/students/quiz-responses (single answer autosave)", st == 200)
    st, body, _ = req("GET", "/api/students/quiz-history", token=tok)
    check("GET /api/students/quiz-history", st == 200 and any(a["id"] == attempt_id for a in body["data"]))

    # ---- fcm token ---------------------------------------------------------
    st, body, _ = req("POST", "/api/students/fcm-token", {"token": "contract-test-fcm-token-xyz", "platform": "android"}, token=tok)
    check("POST /api/students/fcm-token", st == 200 or st == 503, "503 = migration not applied yet" if st == 503 else "")

    # ---- live session: SocketService handshake ---------------------------
    st, tbody, _ = req("POST", "/api/auth/login", {"email": TEACHER, "password": PASSWORD, "user_type": "teacher"})
    ttok = tbody["access_token"]
    st, lb, _ = req("GET", "/api/lectures", token=ttok)
    lec = next((l for l in lb["data"] if l["status"] == "live"), None) or next((l for l in lb["data"] if l["status"] == "scheduled"), None)
    if lec is None:  # create one so the walkthrough is self-contained
        cohort_id = req("GET", "/api/cohorts", token=ttok)[1]["data"][0]["id"]
        lec = req("POST", "/api/lectures", {"cohort_id": cohort_id, "title": "Contract walkthrough", "scheduled_time": "2026-12-20T10:00:00Z"}, token=ttok)[1]["data"]
    if lec["status"] != "live":
        req("POST", f"/api/lectures/{lec['id']}/start", {}, token=ttok)
    session_id = lec["id"]

    async def socket_flow():
        got: dict[str, list] = {}
        teacher = socketio.AsyncClient(reconnection=False)
        student = socketio.AsyncClient(reconnection=False)
        for c, label in ((teacher, "t"), (student, "s")):
            for ev in ("authenticated", "session_created", "session_joined", "participant_joined", "participant_left", "chat_message", "hand_raised", "webrtc_offer", "webrtc_answer", "webrtc_ice_candidate", "session_error", "recording_started", "session_ended", "muted"):
                c.on(ev, (lambda l, e: (lambda d=None: got.setdefault(f"{l}:{e}", []).append(d)))(label, ev))
        await teacher.connect(BASE, transports=["websocket"], auth={"token": ttok})
        await teacher.emit("authenticate", {"token": ttok}); await asyncio.sleep(0.4)
        await teacher.emit("create_session", {"token": ttok, "session_id": session_id, "lecture_id": session_id}); await asyncio.sleep(0.4)
        await teacher.emit("join_session", {"token": ttok, "session_id": session_id}); await asyncio.sleep(0.4)
        # -- exactly what mobile SocketService.connect() does --
        await student.connect(BASE, socketio_path="/socket.io", transports=["websocket", "polling"], auth={"token": tok})
        await student.emit("authenticate", {"token": tok}); await asyncio.sleep(0.4)
        check("socket: student receives `authenticated`", bool(got.get("s:authenticated")))
        await student.emit("join_session", {"token": tok, "session_id": session_id}); await asyncio.sleep(0.6)
        sj = (got.get("s:session_joined") or [None])[0]
        check("socket: `session_joined` carries participants[] (no separate session_participants event)", bool(sj) and isinstance(sj.get("participants"), list) and any(p["user_id"] == student_id for p in sj["participants"]))
        check("socket: teacher receives `participant_joined` for the student", any(d and d.get("user_id") == student_id for d in got.get("t:participant_joined", [])))
        # attendance side effect
        await asyncio.sleep(0.8)
        st2, ab, _ = req("GET", "/api/students/attendance", token=tok)
        check("attendance: joining the live room marks the student present", any(a["lecture_id"] == session_id and a["status"] == "present" for a in ab["data"]))
        # chat as the mobile client sends it
        await student.emit("chat_message", {"token": tok, "session_id": session_id, "user_id": student_id, "user_name": "Student", "message": "hi from mobile", "timestamp": "2026-01-01T00:00:00Z"}); await asyncio.sleep(0.4)
        check("socket: chat_message relayed to teacher with user_id/user_name/message", any(d and d.get("message") == "hi from mobile" and d.get("user_id") == student_id for d in got.get("t:chat_message", [])))
        await student.emit("hand_raised", {"token": tok, "session_id": session_id, "user_id": student_id, "user_name": "Student"}); await asyncio.sleep(0.4)
        check("socket: hand_raised relayed to teacher", bool(got.get("t:hand_raised")))
        # WebRTC: teacher (simple-peer) offer -> mobile answer/ICE in the wrapped shapes
        await teacher.emit("webrtc_offer", {"token": ttok, "target_user_id": student_id, "sdp": {"type": "offer", "sdp": "v=0..."}}); await asyncio.sleep(0.4)
        off = (got.get("s:webrtc_offer") or [None])[0]
        check("socket: mobile receives webrtc_offer {from_user_id, sdp:{type,sdp}}", bool(off) and off.get("sdp", {}).get("type") == "offer" and off.get("from_user_id"))
        await student.emit("webrtc_answer", {"token": tok, "session_id": session_id, "from_user_id": student_id, "target_user_id": off["from_user_id"], "sdp": {"type": "answer", "sdp": "v=0..."}}); await asyncio.sleep(0.4)
        check("socket: teacher receives webrtc_answer from the student", any(d and d.get("from_user_id") == student_id and d["sdp"]["type"] == "answer" for d in got.get("t:webrtc_answer", [])))
        await student.emit("webrtc_ice_candidate", {"token": tok, "session_id": session_id, "from_user_id": student_id, "target_user_id": off["from_user_id"], "candidate": {"type": "candidate", "candidate": {"candidate": "candidate:1 1 udp 1 1.2.3.4 5 typ host", "sdpMid": "0", "sdpMLineIndex": 0}}}); await asyncio.sleep(0.4)
        ice = (got.get("t:webrtc_ice_candidate") or [None])[0]
        check("socket: ICE candidate relayed in simple-peer shape {type:'candidate', candidate:{...}}", bool(ice) and ice["candidate"].get("type") == "candidate" and "sdpMid" in ice["candidate"]["candidate"])
        # mute + end
        await teacher.emit("mute_participant", {"token": ttok, "session_id": session_id, "target_user_id": student_id}); await asyncio.sleep(0.4)
        check("socket: student receives `muted`", bool(got.get("s:muted")))
        await teacher.emit("end_session", {"token": ttok, "session_id": session_id}); await asyncio.sleep(0.6)
        check("socket: student receives `session_ended`", bool(got.get("s:session_ended")))
        await student.disconnect(); await teacher.disconnect()

    asyncio.run(socket_flow())

    # ---- logout ------------------------------------------------------------
    st, body, _ = req("POST", "/api/auth/logout", token=tok)
    check("POST /api/auth/logout", st == 200)

    print(f"\n==== {sum(1 for _, ok, _ in CHECKS if ok)}/{len(CHECKS)} mobile contract checks passed ====")


if __name__ == "__main__":
    main()
