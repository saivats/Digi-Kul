"""Shared fixtures for the live-session tests.

Requires a Redis at REDIS_URL (default redis://localhost:6379/9 — DB 9 so we
never collide with a dev instance). The multi-worker server fixture runs the
real ASGI app under `uvicorn --workers 2` in a subprocess, so every test in
that file exercises cross-process state and Redis pub/sub for real.
"""

from __future__ import annotations

import asyncio
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

import pytest
import redis
import socketio

BACKEND_DIR = Path(__file__).resolve().parents[1]
REDIS_URL = os.environ.get("TEST_REDIS_URL", "redis://localhost:6379/9")
SECRET = "test-secret-key-for-live-session-tests"


def _free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


@pytest.fixture(scope="session")
def redis_client():
    client = redis.Redis.from_url(REDIS_URL)
    try:
        client.ping()
    except redis.ConnectionError:  # pragma: no cover
        pytest.skip(f"Redis not reachable at {REDIS_URL}")
    client.flushdb()
    yield client
    client.flushdb()


@pytest.fixture(scope="session")
def server_env(redis_client):
    env = os.environ.copy()
    env.update({
        "SECRET_KEY": SECRET,
        "REDIS_URL": REDIS_URL,
        "SUPABASE_URL": "https://placeholder.supabase.co",
        "SUPABASE_KEY": "placeholder",
        "CORS_ORIGINS": "http://localhost:3000",
        "LOG_LEVEL": "INFO",
        # Tight chat limit so the rate-limit test is fast and deterministic.
        "SOCKET_CHAT_RATE": "2",
        "SOCKET_CHAT_BURST": "5",
    })
    # Don't let a developer's backend/.env leak into the test server.
    env.pop("ENV_FILE", None)
    return env


@pytest.fixture(scope="session")
def multiworker_server(server_env, tmp_path_factory):
    """Real uvicorn, 2 workers, real Redis. Yields (base_url, log_path)."""
    port = _free_port()
    log_path = tmp_path_factory.mktemp("logs") / "uvicorn.log"
    log = open(log_path, "w")
    proc = subprocess.Popen(
        [
            sys.executable, "-m", "uvicorn", "app.main:app",
            "--host", "127.0.0.1", "--port", str(port),
            "--workers", "2", "--log-level", "info",
        ],
        cwd=BACKEND_DIR,
        env={**server_env, "PYTHONPATH": str(BACKEND_DIR)},
        stdout=log,
        stderr=subprocess.STDOUT,
    )
    base = f"http://127.0.0.1:{port}"
    deadline = time.time() + 30
    import urllib.request

    while time.time() < deadline:
        if proc.poll() is not None:
            log.flush()
            raise RuntimeError(f"uvicorn died:\n{log_path.read_text()}")
        try:
            with urllib.request.urlopen(base + "/api/health", timeout=1) as r:
                if r.status == 200:
                    break
        except Exception:
            time.sleep(0.25)
    else:  # pragma: no cover
        proc.kill()
        raise RuntimeError(f"server did not come up:\n{log_path.read_text()}")
    yield base, log_path
    proc.terminate()
    try:
        proc.wait(10)
    except subprocess.TimeoutExpired:  # pragma: no cover
        proc.kill()
    log.close()


def make_token(user_id: str, user_type: str, name: str, institution_id: str = "inst-1") -> str:
    from jose import jwt

    return jwt.encode(
        {"sub": user_id, "user_type": user_type, "user_name": name, "institution_id": institution_id},
        SECRET,
        algorithm="HS256",
    )


class Client:
    """socketio.AsyncClient wrapper that records every event into per-event
    queues so tests can `await c.expect("participant_joined")`."""

    EVENTS = [
        "authenticated", "auth_error", "session_created", "session_joined",
        "session_error", "session_ended", "participant_joined", "participant_left",
        "webrtc_offer", "webrtc_answer", "webrtc_ice_candidate", "chat_message",
        "whiteboard_stroke", "whiteboard_clear", "recording_started",
        "recording_stopped", "poll_created", "poll_response", "hand_raised",
        "muted", "rate_limited",
    ]

    def __init__(self, base_url: str, token: str, label: str) -> None:
        self.base_url = base_url
        self.token = token
        self.label = label
        self.sio = socketio.AsyncClient(reconnection=False)
        self.queues: dict[str, asyncio.Queue] = {e: asyncio.Queue() for e in self.EVENTS}
        for event in self.EVENTS:
            self.sio.on(event, self._handler(event))

    def _handler(self, event):
        async def _h(data=None):
            await self.queues[event].put(data)
        return _h

    async def connect(self):
        await self.sio.connect(self.base_url, transports=["websocket"], auth={"token": self.token})
        return self

    async def emit(self, event: str, data: dict | None = None):
        await self.sio.emit(event, {"token": self.token, **(data or {})})

    async def expect(self, event: str, timeout: float = 5.0):
        try:
            return await asyncio.wait_for(self.queues[event].get(), timeout)
        except asyncio.TimeoutError:
            raise AssertionError(f"[{self.label}] timed out waiting for '{event}'") from None

    async def expect_none(self, event: str, quiet: float = 0.8):
        try:
            data = await asyncio.wait_for(self.queues[event].get(), quiet)
        except asyncio.TimeoutError:
            return
        raise AssertionError(f"[{self.label}] unexpectedly received '{event}': {data}")

    def drain(self, event: str) -> list:
        out = []
        q = self.queues[event]
        while not q.empty():
            out.append(q.get_nowait())
        return out

    async def close(self):
        if self.sio.connected:
            await self.sio.disconnect()

    @property
    def connected(self) -> bool:
        return self.sio.connected
