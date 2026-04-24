from datetime import datetime, timezone

from app.database import get_supabase


def list_institutions(*, is_active: bool | None = True) -> list[dict]:
    db = get_supabase()
    query = db.table("institutions").select("*")
    if is_active is not None:
        query = query.eq("is_active", is_active)
    return query.order("created_at", desc=True).execute().data or []


def get_institution(institution_id: str) -> dict | None:
    db = get_supabase()
    result = db.table("institutions").select("*").eq("id", institution_id).execute()
    return result.data[0] if result.data else None


def create_institution(
    *,
    name: str,
    domain: str,
    subdomain: str | None = None,
    description: str | None = None,
    contact_email: str | None = None,
    contact_phone: str | None = None,
    address: str | None = None,
    website: str | None = None,
    primary_color: str = "#007bff",
    created_by: str | None = None,
) -> dict:
    db = get_supabase()
    payload = {
        "name": name,
        "domain": domain,
        "subdomain": subdomain or domain.split(".")[0],
        "description": description,
        "contact_email": contact_email,
        "contact_phone": contact_phone,
        "address": address,
        "website": website,
        "primary_color": primary_color,
        "created_by": created_by,
        "is_active": True,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("institutions").insert(payload).execute()
    return result.data[0] if result.data else {}


def update_institution(institution_id: str, updates: dict) -> dict | None:
    db = get_supabase()
    updates["updated_at"] = datetime.now(timezone.utc).isoformat()
    result = db.table("institutions").update(updates).eq("id", institution_id).execute()
    return result.data[0] if result.data else None


def deactivate_institution(institution_id: str) -> bool:
    db = get_supabase()
    result = (
        db.table("institutions")
        .update({"is_active": False, "updated_at": datetime.now(timezone.utc).isoformat()})
        .eq("id", institution_id)
        .execute()
    )
    return bool(result.data)


def get_platform_stats() -> dict:
    db = get_supabase()
    institutions = db.table("institutions").select("id", count="exact").execute()
    teachers = db.table("teachers").select("id", count="exact").execute()
    students = db.table("students").select("id", count="exact").execute()
    cohorts = db.table("cohorts").select("id", count="exact").execute()
    lectures = db.table("lectures").select("id", count="exact").execute()
    return {
        "total_institutions": institutions.count or 0,
        "total_teachers": teachers.count or 0,
        "total_students": students.count or 0,
        "total_cohorts": cohorts.count or 0,
        "total_lectures": lectures.count or 0,
    }


def get_institution_stats(institution_id: str) -> dict:
    db = get_supabase()
    teachers = db.table("teachers").select("id", count="exact").eq("institution_id", institution_id).execute()
    students = db.table("students").select("id", count="exact").eq("institution_id", institution_id).execute()
    cohorts = db.table("cohorts").select("id", count="exact").eq("institution_id", institution_id).execute()
    lectures = db.table("lectures").select("id", count="exact").eq("institution_id", institution_id).execute()
    return {
        "total_teachers": teachers.count or 0,
        "total_students": students.count or 0,
        "total_cohorts": cohorts.count or 0,
        "total_lectures": lectures.count or 0,
    }
