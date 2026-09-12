import logging
import os
from contextlib import asynccontextmanager

from dotenv import load_dotenv

load_dotenv()

import socketio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import (
    auth,
    cohort,
    institution,
    lecture,
    material,
    quiz,
    recording,
    student,
    super_admin,
    teacher,
    public,
)
from app.socket_manager import session_store, sio

settings = get_settings()
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    # pid in every line: with --workers N you can see which process served what
    format="%(asctime)s %(levelname)s [pid %(process)d] %(name)s: %(message)s",
)
logger = logging.getLogger("digi-kul")


@asynccontextmanager
async def lifespan(_app: FastAPI):
    # Fail fast if Redis is unreachable: the live-session store and the
    # Socket.IO cross-worker broadcast both depend on it.
    try:
        await session_store.ping()
        logger.info("Redis reachable at %s", settings.redis_url)
    except Exception as exc:  # pragma: no cover - startup guard
        raise RuntimeError(
            f"Cannot reach Redis at REDIS_URL={settings.redis_url!r}. "
            "Live sessions need Redis (docker-compose provides the `redis` service; "
            "for local dev run `redis-server` and set REDIS_URL=redis://localhost:6379/0)."
        ) from exc
    yield
    await session_store.close()


fastapi_app = FastAPI(
    title="Digi-Kul API",
    description="Digital Gurukul — Bringing quality education to every corner of India",
    version="2.0.0",
    lifespan=lifespan,
)

fastapi_app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

fastapi_app.include_router(auth.router)
fastapi_app.include_router(institution.router)
fastapi_app.include_router(super_admin.router)
fastapi_app.include_router(cohort.router)
fastapi_app.include_router(lecture.router)
fastapi_app.include_router(material.router)
fastapi_app.include_router(quiz.router)
fastapi_app.include_router(student.router)
fastapi_app.include_router(teacher.router)
fastapi_app.include_router(recording.router)
fastapi_app.include_router(public.router)

for folder in [settings.upload_folder, settings.compressed_folder, settings.recording_directory]:
    os.makedirs(folder, exist_ok=True)
    for sub in ["audio", "images", "documents"]:
        os.makedirs(os.path.join(folder, sub), exist_ok=True)


@fastapi_app.get("/api/health", tags=["System"])
def health_check():
    return {"status": "healthy", "service": "digi-kul-backend", "version": "2.0.0"}


# Socket.IO wraps FastAPI at the ASGI root so the handshake path is
# `/socket.io/` — the socket.io-client default and what nginx.conf proxies.
# (The previous `app.mount("/ws", sio_app)` never matched: python-socketio's
# ASGIApp compares the *full* request path against `/socket.io`, so both
# `/socket.io/` and `/ws/socket.io/` returned 404.)
# `uvicorn app.main:app` keeps working — `app` is the combined ASGI app.
app = socketio.ASGIApp(sio, other_asgi_app=fastapi_app, socketio_path="socket.io")
