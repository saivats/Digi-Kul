"""Attendance is derived from live-session participation.

When a student's socket joins a live lecture we upsert a `present` row with
joined_at; when they leave/disconnect we stamp left_at. Teachers/admins can
later override `status` (late/excused/absent) through the attendance table.
"""

from datetime import datetime, timezone

from app.database import get_supabase


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def mark_joined(*, institution_id: str, lecture_id: str, student_id: str) -> dict | None:
    db = get_supabase()
    existing = (
        db.table("attendance")
        .select("id, status")
        .eq("lecture_id", lecture_id)
        .eq("student_id", student_id)
        .execute()
    )
    if existing.data:
        row = existing.data[0]
        updates = {"left_at": None}
        # Don't downgrade a teacher's explicit 'late'/'excused'; absent -> present.
        if row.get("status") == "absent":
            updates["status"] = "present"
        result = db.table("attendance").update(updates).eq("id", row["id"]).execute()
        return result.data[0] if result.data else row
    payload = {
        "institution_id": institution_id or None,
        "lecture_id": lecture_id,
        "student_id": student_id,
        "status": "present",
        "joined_at": _now(),
        "created_at": _now(),
    }
    result = db.table("attendance").insert(payload).execute()
    return result.data[0] if result.data else None


def mark_left(*, lecture_id: str, student_id: str) -> None:
    db = get_supabase()
    db.table("attendance").update({"left_at": _now()}).eq("lecture_id", lecture_id).eq(
        "student_id", student_id
    ).execute()


def list_for_student(student_id: str, institution_id: str) -> list[dict]:
    """Attendance rows shaped for the student app: one per lecture the
    student was expected at (all lectures in their cohorts that have ended or
    are live), status defaulting to 'absent' when no row exists."""
    from app.services import cohort_service, lecture_service

    db = get_supabase()
    cohort_ids = [c["id"] for c in cohort_service.get_student_cohorts(student_id, institution_id)]
    lectures = lecture_service.list_lectures_for_cohorts(cohort_ids, institution_id)
    # Only lectures that have happened (or are happening) count.
    lectures = [l for l in lectures if l.get("status") in ("live", "ended")]

    rows = (
        db.table("attendance")
        .select("*")
        .eq("student_id", student_id)
        .execute()
        .data
        or []
    )
    by_lecture = {r["lecture_id"]: r for r in rows}

    out: list[dict] = []
    for lec in lectures:
        row = by_lecture.get(lec["id"])
        out.append({
            "id": row["id"] if row else f"absent-{lec['id']}",
            "lecture_id": lec["id"],
            "lecture_title": lec.get("title", ""),
            "lecture_date": lec.get("scheduled_time"),
            "status": (row or {}).get("status", "absent"),
            "joined_at": (row or {}).get("joined_at"),
            "left_at": (row or {}).get("left_at"),
            "cohort_id": lec.get("cohort_id"),
        })
    out.sort(key=lambda r: r["lecture_date"] or "", reverse=True)
    return out


def summary(records: list[dict]) -> dict:
    total = len(records)
    present = sum(1 for r in records if r["status"] in ("present", "late"))
    pct = 100.0 if total == 0 else round(present / total * 100, 1)
    return {"total_classes": total, "present_classes": present, "percentage": pct}
