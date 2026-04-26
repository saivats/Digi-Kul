import os

from dotenv import load_dotenv

load_dotenv()

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
from app.socket_manager import sio_app

settings = get_settings()

app = FastAPI(
    title="Digi-Kul API",
    description="Digital Gurukul — Bringing quality education to every corner of India",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(institution.router)
app.include_router(super_admin.router)
app.include_router(cohort.router)
app.include_router(lecture.router)
app.include_router(material.router)
app.include_router(quiz.router)
app.include_router(student.router)
app.include_router(teacher.router)
app.include_router(recording.router)
app.include_router(public.router)

app.mount("/ws", sio_app)

for folder in [settings.upload_folder, settings.compressed_folder, settings.recording_directory]:
    os.makedirs(folder, exist_ok=True)
    for sub in ["audio", "images", "documents"]:
        os.makedirs(os.path.join(folder, sub), exist_ok=True)


@app.get("/api/health", tags=["System"])
def health_check():
    return {"status": "healthy", "service": "digi-kul-backend", "version": "2.0.0"}
