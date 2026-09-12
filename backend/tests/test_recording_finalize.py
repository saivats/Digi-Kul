"""start_recording -> stop_recording must finalize the recording row.

Runs the real ASGI app in-process (single worker, real Redis) so we can swap
`recording_service.get_supabase` for an in-memory fake that implements the
subset of the supabase-py query builder that recording_service uses. The
finalize logic (stopped_at, duration, participants, stats.status) is real.
"""

from __future__ import annotations

import asyncio
import uuid
from datetime import datetime, timedelta, timezone

import pytest
import pytest_asyncio
import uvicorn

from tests.conftest import REDIS_URL, SECRET, Client, make_token, _free_port

pytestmark = pytest.mark.asyncio(loop_scope="session")


# --------------------------------------------------------------------------
# Minimal in-memory stand-in for supabase-py's PostgREST builder
# --------------------------------------------------------------------------
class _Result:
    def __init__(self, data):
        self.data = data


class _Query:
    def __init__(self, table: "_Table"):
        self.t = table
        self.filters: list[tuple[str, object]] = []
        self.op: tuple[str, dict | None] = ("select", None)

    def select(self, *_a, **_k):
        self.op = ("select", None)
        return self

    def insert(self, payload: dict):
        self.op = ("insert", payload)
        return self

    def update(self, payload: dict):
        self.op = ("update", payload)
        return self

    def eq(self, col, val):
        self.filters.append((col, val))
        return self

    def order(self, *_a, **_k):
        return self

    def _match(self, row):
        return all(row.get(c) == v for c, v in self.filters)

    def execute(self):
        kind, payload = self.op
        if kind == "insert":
            row = {"id": str(uuid.uuid4()), **payload}
            self.t.rows.append(row)
            return _Result([row])
        if kind == "update":
            out = []
            for row in self.t.rows:
                if self._match(row):
                    row.update(payload)
                    out.append(dict(row))
            return _Result(out)
        return _Result([dict(r) for r in self.t.rows if self._match(r)])


class _Table:
    def __init__(self):
        self.rows: list[dict] = []


class FakeSupabase:
    def __init__(self):
        self.tables: dict[str, _Table] = {}

    def table(self, name):
        return _Query(self.tables.setdefault(name, _Table()))


@pytest_asyncio.fixture(loop_scope="session")
async def inprocess_server(monkeypatch, redis_client):
    monkeypatch.setenv("SECRET_KEY", SECRET)
    monkeypatch.setenv("REDIS_URL", REDIS_URL)
    monkeypatch.setenv("SUPABASE_URL", "https://placeholder.supabase.co")
    monkeypatch.setenv("SUPABASE_KEY", "placeholder")

    from app.config import get_settings
    get_settings.cache_clear()
    # Import after env is set so socket_manager binds to the test Redis.
    import importlib
    import app.socket_manager as sm
    import app.main as main
    importlib.reload(sm)
    importlib.reload(main)
    from app.services import recording_service

    fake = FakeSupabase()
    monkeypatch.setattr(recording_service, "get_supabase", lambda: fake)

    port = _free_port()
    config = uvicorn.Config(main.app, host="127.0.0.1", port=port, log_level="warning", lifespan="on")
    server = uvicorn.Server(config)
    task = asyncio.create_task(server.serve())
    while not server.started:
        await asyncio.sleep(0.05)
    yield f"http://127.0.0.1:{port}", fake
    server.should_exit = True
    await task


async def test_stop_recording_finalizes_row(inprocess_server):
    base, fake = inprocess_server
    session_id = f"lec-{uuid.uuid4().hex[:8]}"
    teacher = await Client(base, make_token("t-1", "teacher", "Ms. Rao", "inst-9"), "teacher").connect()
    await teacher.emit("authenticate")
    await teacher.expect("authenticated")
    await teacher.emit("create_session", {"session_id": session_id, "cohort_id": "cohort-7"})
    await teacher.expect("session_created")
    await teacher.emit("join_session", {"session_id": session_id})
    await teacher.expect("session_joined")

    student = await Client(base, make_token("s-1", "student", "Asha", "inst-9"), "student").connect()
    await student.emit("authenticate")
    await student.expect("authenticated")
    await student.emit("join_session", {"session_id": session_id})
    joined = await student.expect("session_joined")
    assert joined["is_recording"] is False

    # ---- start -----------------------------------------------------------
    await teacher.emit("start_recording", {"session_id": session_id, "title": "Physics L1"})
    started = await teacher.expect("recording_started")
    rec_id = started["recording_id"]
    assert (await student.expect("recording_started"))["recording_id"] == rec_id

    rows = fake.tables["session_recordings"].rows
    assert len(rows) == 1
    row = rows[0]
    assert row["id"] == rec_id
    assert row["institution_id"] == "inst-9" and row["cohort_id"] == "cohort-7"
    assert row["lecture_id"] == session_id and row["teacher_id"] == "t-1"
    assert row["title"] == "Physics L1"
    assert row.get("stopped_at") is None and row.get("duration") is None

    # Second start while recording is refused.
    await teacher.emit("start_recording", {"session_id": session_id})
    assert (await teacher.expect("session_error"))["error"] == "Recording already in progress"

    # Late joiner learns a recording is in progress.
    late = await Client(base, make_token("s-2", "student", "Bilal", "inst-9"), "late").connect()
    await late.emit("authenticate")
    await late.expect("authenticated")
    await late.emit("join_session", {"session_id": session_id})
    assert (await late.expect("session_joined"))["is_recording"] is True

    # Pretend it started 90s ago so the duration is meaningful.
    row["started_at"] = (datetime.now(timezone.utc) - timedelta(seconds=90)).isoformat()

    # ---- stop ------------------------------------------------------------
    await teacher.emit("stop_recording", {"session_id": session_id})
    stopped = await teacher.expect("recording_stopped")
    assert stopped["recording_id"] == rec_id
    assert 89 <= stopped["duration"] <= 92
    assert (await student.expect("recording_stopped"))["recording_id"] == rec_id

    row = fake.tables["session_recordings"].rows[0]
    assert row["stopped_at"] is not None
    assert 89 <= row["duration"] <= 92
    assert row["stats"]["status"] == "completed"
    assert row["stats"]["participant_count"] == 3
    assert sorted(row["participants"]) == ["s-1", "s-2", "t-1"]

    # Stopping again: nothing in progress.
    await teacher.emit("stop_recording", {"session_id": session_id})
    assert (await teacher.expect("session_error"))["error"] == "No recording in progress"

    # ---- end_session finalizes an in-flight recording too -----------------
    await teacher.emit("start_recording", {"session_id": session_id, "title": "Take 2"})
    rec2 = (await teacher.expect("recording_started"))["recording_id"]
    await teacher.emit("end_session", {"session_id": session_id})
    assert (await teacher.expect("recording_stopped"))["recording_id"] == rec2
    await teacher.expect("session_ended")
    row2 = next(r for r in fake.tables["session_recordings"].rows if r["id"] == rec2)
    assert row2["stopped_at"] is not None and row2["stats"]["status"] == "completed"

    for c in (teacher, student, late):
        await c.close()


@pytest.mark.asyncio(loop_scope="session")
async def test_finalize_is_idempotent_and_handles_missing():
    from app.services import recording_service

    fake = FakeSupabase()
    recording_service.get_supabase = lambda: fake  # type: ignore[assignment]
    try:
        assert recording_service.finalize_recording("does-not-exist") is None
        started = (datetime.now(timezone.utc) - timedelta(seconds=30)).isoformat()
        row = fake.table("session_recordings").insert({"started_at": started, "stats": {"bitrate": 1}}).execute().data[0]
        first = recording_service.finalize_recording(row["id"], participants=["a"])
        assert first["stats"] == {"bitrate": 1, "status": "completed", "participant_count": 1}
        assert 29 <= first["duration"] <= 31
        again = recording_service.finalize_recording(row["id"])
        assert again["stopped_at"] == first["stopped_at"], "second call must not move stopped_at"
    finally:
        del recording_service.get_supabase
        import importlib
        importlib.reload(recording_service)
