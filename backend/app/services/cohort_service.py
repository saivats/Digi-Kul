from datetime import datetime, timezone

from app.database import get_supabase


def list_cohorts_for_institution(institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("cohorts")
        .select("*")
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("created_at", desc=True)
        .execute()
        .data
        or []
    )


def get_cohort(cohort_id: str, institution_id: str) -> dict | None:
    db = get_supabase()
    result = (
        db.table("cohorts")
        .select("*")
        .eq("id", cohort_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None


def create_cohort(
    *,
    institution_id: str,
    name: str,
    description: str | None = None,
    enrollment_code: str,
    max_students: int = 50,
    academic_year: str | None = None,
    semester: str | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    created_by: str | None = None,
) -> dict:
    db = get_supabase()
    payload = {
        "institution_id": institution_id,
        "name": name,
        "description": description,
        "enrollment_code": enrollment_code,
        "max_students": max_students,
        "academic_year": academic_year,
        "semester": semester,
        "start_date": start_date,
        "end_date": end_date,
        "is_active": True,
        "created_by": created_by,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("cohorts").insert(payload).execute()
    return result.data[0] if result.data else {}


def delete_cohort(cohort_id: str, institution_id: str) -> bool:
    db = get_supabase()
    result = (
        db.table("cohorts")
        .update({"is_active": False})
        .eq("id", cohort_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return bool(result.data)


def update_cohort(cohort_id: str, institution_id: str, updates: dict) -> dict | None:
    db = get_supabase()
    # Filter out sensitive or non-updatable fields
    safe_fields = {"name", "description", "enrollment_code", "max_students", "academic_year", "semester", "start_date", "end_date", "is_active"}
    filtered = {k: v for k, v in updates.items() if k in safe_fields}
    if not filtered:
        return None
    
    result = (
        db.table("cohorts")
        .update(filtered)
        .eq("id", cohort_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None


def get_cohort_students(cohort_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    enrollments = (
        db.table("enrollments")
        .select("student_id")
        .eq("cohort_id", cohort_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .execute()
        .data
        or []
    )
    student_ids = [e["student_id"] for e in enrollments]
    if not student_ids:
        return []
    return (
        db.table("students")
        .select("id, name, email, student_id, phone, is_active")
        .in_("id", student_ids)
        .execute()
        .data
        or []
    )


def add_student_to_cohort(cohort_id: str, student_id: str, institution_id: str) -> dict:
    db = get_supabase()
    existing = (
        db.table("enrollments")
        .select("id")
        .eq("student_id", student_id)
        .eq("cohort_id", cohort_id)
        .execute()
    )
    if existing.data:
        return existing.data[0]
    payload = {
        "institution_id": institution_id,
        "student_id": student_id,
        "cohort_id": cohort_id,
        "enrolled_at": datetime.now(timezone.utc).isoformat(),
        "status": "active",
        "is_active": True,
    }
    result = db.table("enrollments").insert(payload).execute()
    return result.data[0] if result.data else {}


def remove_student_from_cohort(cohort_id: str, student_id: str, institution_id: str) -> bool:
    db = get_supabase()
    result = (
        db.table("enrollments")
        .update({"is_active": False, "status": "inactive"})
        .eq("student_id", student_id)
        .eq("cohort_id", cohort_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return bool(result.data)


def join_cohort_by_code(student_id: str, enrollment_code: str, institution_id: str) -> dict | None:
    db = get_supabase()
    cohort_result = (
        db.table("cohorts")
        .select("*")
        .eq("enrollment_code", enrollment_code)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .execute()
    )
    if not cohort_result.data:
        return None
    cohort = cohort_result.data[0]
    add_student_to_cohort(cohort["id"], student_id, institution_id)
    return cohort


def assign_teacher_to_cohort(cohort_id: str, teacher_id: str, institution_id: str) -> dict:
    db = get_supabase()
    existing = (
        db.table("teacher_cohorts")
        .select("id")
        .eq("teacher_id", teacher_id)
        .eq("cohort_id", cohort_id)
        .execute()
    )
    if existing.data:
        return existing.data[0]
    payload = {
        "teacher_id": teacher_id,
        "cohort_id": cohort_id,
        "role": "teacher",
        "assigned_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("teacher_cohorts").insert(payload).execute()
    return result.data[0] if result.data else {}


def get_teacher_cohorts(teacher_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    tc = (
        db.table("teacher_cohorts")
        .select("cohort_id")
        .eq("teacher_id", teacher_id)
        .execute()
        .data
        or []
    )
    cohort_ids = [r["cohort_id"] for r in tc]
    if not cohort_ids:
        return []
    return (
        db.table("cohorts")
        .select("*")
        .in_("id", cohort_ids)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .execute()
        .data
        or []
    )


def get_student_cohorts(student_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    enrollments = (
        db.table("enrollments")
        .select("cohort_id")
        .eq("student_id", student_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .execute()
        .data
        or []
    )
    cohort_ids = [e["cohort_id"] for e in enrollments]
    if not cohort_ids:
        return []
    return (
        db.table("cohorts")
        .select("*")
        .in_("id", cohort_ids)
        .eq("is_active", True)
        .execute()
        .data
        or []
    )
