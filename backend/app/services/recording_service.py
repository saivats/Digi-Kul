from datetime import datetime, timezone

from app.database import get_supabase


def create_recording(
    *,
    institution_id: str,
    cohort_id: str,
    lecture_id: str,
    teacher_id: str,
    session_id: str,
    title: str | None = None,
    description: str | None = None,
    recording_path: str | None = None,
    file_size: int | None = None,
    duration: int | None = None,
) -> dict:
    db = get_supabase()
    payload = {
        "institution_id": institution_id,
        "cohort_id": cohort_id,
        "lecture_id": lecture_id,
        "teacher_id": teacher_id,
        "session_id": session_id,
        "title": title,
        "description": description,
        "recording_path": recording_path,
        "file_size": file_size,
        "duration": duration,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "is_active": True,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("session_recordings").insert(payload).execute()
    return result.data[0] if result.data else {}


def get_recording(recording_id: str, institution_id: str) -> dict | None:
    db = get_supabase()
    result = (
        db.table("session_recordings")
        .select("*")
        .eq("id", recording_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None


def list_recordings_for_lecture(lecture_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("session_recordings")
        .select("*")
        .eq("lecture_id", lecture_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("created_at", desc=True)
        .execute()
        .data
        or []
    )


def list_recordings_for_cohort(cohort_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("session_recordings")
        .select("*")
        .eq("cohort_id", cohort_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("created_at", desc=True)
        .execute()
        .data
        or []
    )


def delete_recording(recording_id: str, institution_id: str) -> bool:
    db = get_supabase()
    result = (
        db.table("session_recordings")
        .update({"is_active": False})
        .eq("id", recording_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return bool(result.data)


def increment_download_count(recording_id: str) -> None:
    db = get_supabase()
    rec = db.table("session_recordings").select("download_count").eq("id", recording_id).execute()
    if rec.data:
        current = rec.data[0].get("download_count", 0) or 0
        db.table("session_recordings").update({"download_count": current + 1}).eq("id", recording_id).execute()
