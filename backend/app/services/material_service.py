from datetime import datetime, timezone

from app.database import get_supabase


def create_material(
    *,
    institution_id: str,
    teacher_id: str,
    title: str,
    description: str | None = None,
    file_path: str,
    file_name: str,
    file_type: str,
    file_size: int | None = None,
    lecture_id: str | None = None,
    cohort_id: str | None = None,
) -> dict:
    db = get_supabase()
    payload = {
        "institution_id": institution_id,
        "teacher_id": teacher_id,
        "title": title,
        "description": description,
        "file_path": file_path,
        "file_name": file_name,
        "file_type": file_type,
        "file_size": file_size,
        "lecture_id": lecture_id,
        "cohort_id": cohort_id,
        "is_active": True,
        "uploaded_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("materials").insert(payload).execute()
    return result.data[0] if result.data else {}


def list_materials_for_lecture(lecture_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("materials")
        .select("*")
        .eq("lecture_id", lecture_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("uploaded_at", desc=True)
        .execute()
        .data
        or []
    )


def list_materials_for_cohort(cohort_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("materials")
        .select("*")
        .eq("cohort_id", cohort_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("uploaded_at", desc=True)
        .execute()
        .data
        or []
    )


def get_material(material_id: str, institution_id: str) -> dict | None:
    db = get_supabase()
    result = (
        db.table("materials")
        .select("*")
        .eq("id", material_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None


def delete_material(material_id: str, institution_id: str) -> bool:
    db = get_supabase()
    result = (
        db.table("materials")
        .update({"is_active": False})
        .eq("id", material_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return bool(result.data)


def increment_download_count(material_id: str) -> None:
    db = get_supabase()
    material = db.table("materials").select("download_count").eq("id", material_id).execute()
    if material.data:
        current = material.data[0].get("download_count", 0) or 0
        db.table("materials").update({"download_count": current + 1}).eq("id", material_id).execute()


def list_materials_for_cohorts(cohort_ids: list[str], institution_id: str) -> list[dict]:
    """Materials attached to any of the cohorts OR to lectures in them."""
    if not cohort_ids:
        return []
    db = get_supabase()
    lecture_ids = [
        l["id"]
        for l in (
            db.table("lectures").select("id").in_("cohort_id", cohort_ids).eq("institution_id", institution_id).execute().data
            or []
        )
    ]
    query = (
        db.table("materials")
        .select("*, teachers(name)")
        .eq("institution_id", institution_id)
        .eq("is_active", True)
    )
    clauses = [f"cohort_id.in.({','.join(cohort_ids)})"]
    if lecture_ids:
        clauses.append(f"lecture_id.in.({','.join(lecture_ids)})")
    query = query.or_(",".join(clauses))
    rows = query.order("uploaded_at", desc=True).execute().data or []
    return [shape_for_client(r) for r in rows]


def shape_for_client(row: dict) -> dict:
    """Add the fields clients render: download_url (relative to the API
    origin — the auth interceptor adds the bearer token), file_size_bytes,
    a short file_type (pdf/png/…) and uploaded_by (teacher name)."""
    teacher = row.pop("teachers", None) or {}
    out = dict(row)
    name = row.get("file_name") or ""
    ext = name.rsplit(".", 1)[-1].lower() if "." in name else ""
    out["mime_type"] = row.get("file_type")
    out["file_type"] = ext or (row.get("file_type") or "").split("/")[-1] or "file"
    out["file_size_bytes"] = row.get("file_size") or 0
    out["uploaded_by"] = teacher.get("name", "") if isinstance(teacher, dict) else ""
    out["download_url"] = f"/api/materials/{row['id']}/file"
    return out
