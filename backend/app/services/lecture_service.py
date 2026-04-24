from datetime import datetime, timezone

from app.database import get_supabase


def create_lecture(
    *,
    institution_id: str,
    cohort_id: str,
    teacher_id: str,
    title: str,
    description: str | None = None,
    scheduled_time: str,
    duration: int = 60,
) -> dict:
    db = get_supabase()
    payload = {
        "institution_id": institution_id,
        "cohort_id": cohort_id,
        "teacher_id": teacher_id,
        "title": title,
        "description": description,
        "scheduled_time": scheduled_time,
        "duration": duration,
        "status": "scheduled",
        "is_active": True,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("lectures").insert(payload).execute()
    return result.data[0] if result.data else {}


def get_lecture(lecture_id: str, institution_id: str) -> dict | None:
    db = get_supabase()
    result = (
        db.table("lectures")
        .select("*")
        .eq("id", lecture_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None


def list_lectures_for_teacher(teacher_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("lectures")
        .select("*")
        .eq("teacher_id", teacher_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("scheduled_time", desc=True)
        .execute()
        .data
        or []
    )


def list_lectures_for_cohort(cohort_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("lectures")
        .select("*")
        .eq("cohort_id", cohort_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("scheduled_time", desc=True)
        .execute()
        .data
        or []
    )


def update_lecture(lecture_id: str, institution_id: str, updates: dict) -> dict | None:
    db = get_supabase()
    result = (
        db.table("lectures")
        .update(updates)
        .eq("id", lecture_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None


def delete_lecture(lecture_id: str, institution_id: str) -> bool:
    db = get_supabase()
    result = (
        db.table("lectures")
        .update({"is_active": False, "status": "cancelled"})
        .eq("id", lecture_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return bool(result.data)


def get_active_lectures(institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("lectures")
        .select("*")
        .eq("institution_id", institution_id)
        .eq("status", "live")
        .eq("is_active", True)
        .execute()
        .data
        or []
    )


def set_lecture_status(lecture_id: str, institution_id: str, status: str) -> dict | None:
    db = get_supabase()
    result = (
        db.table("lectures")
        .update({"status": status})
        .eq("id", lecture_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None
