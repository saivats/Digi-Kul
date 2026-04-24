from fastapi import APIRouter, Depends, HTTPException, status

from app.database import get_supabase
from app.services import cohort_service, lecture_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/teachers", tags=["Teachers"])


@router.get("/me")
def get_profile(current_user: dict = Depends(require_role("teacher"))):
    db = get_supabase()
    result = db.table("teachers").select("*").eq("id", current_user["user_id"]).execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
    teacher = result.data[0]
    teacher.pop("password_hash", None)
    return {"success": True, "data": teacher, "error": None}


@router.patch("/me")
def update_profile(
    updates: dict,
    current_user: dict = Depends(require_role("teacher")),
):
    db = get_supabase()
    safe_fields = {"phone", "avatar_url", "bio", "department"}
    filtered = {k: v for k, v in updates.items() if k in safe_fields}
    if not filtered:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No updatable fields provided")
    result = db.table("teachers").update(filtered).eq("id", current_user["user_id"]).execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
    teacher = result.data[0]
    teacher.pop("password_hash", None)
    return {"success": True, "data": teacher, "error": None}


@router.get("/cohorts")
def my_cohorts(current_user: dict = Depends(require_role("teacher"))):
    institution_id = current_user["institution_id"]
    data = cohort_service.get_teacher_cohorts(current_user["user_id"], institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/lectures")
def my_lectures(current_user: dict = Depends(require_role("teacher"))):
    institution_id = current_user["institution_id"]
    data = lecture_service.list_lectures_for_teacher(current_user["user_id"], institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("")
def list_teachers(
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin")),
):
    db = get_supabase()
    institution_id = current_user["institution_id"]
    if not institution_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No institution context")
    result = (
        db.table("teachers")
        .select("id, name, email, subject, department, phone, is_active, created_at, last_login")
        .eq("institution_id", institution_id)
        .order("name")
        .execute()
    )
    return {"success": True, "data": result.data or [], "error": None}


@router.get("/{teacher_id}")
def get_teacher(
    teacher_id: str,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin")),
):
    db = get_supabase()
    institution_id = current_user["institution_id"]
    result = (
        db.table("teachers")
        .select("id, name, email, subject, department, phone, is_active, created_at, last_login")
        .eq("id", teacher_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
    return {"success": True, "data": result.data[0], "error": None}


@router.post("/{teacher_id}/toggle-active")
def toggle_active(
    teacher_id: str,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin")),
):
    db = get_supabase()
    institution_id = current_user["institution_id"]
    teacher = (
        db.table("teachers")
        .select("is_active")
        .eq("id", teacher_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    if not teacher.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
    new_status = not teacher.data[0]["is_active"]
    db.table("teachers").update({"is_active": new_status}).eq("id", teacher_id).execute()
    return {"success": True, "data": {"is_active": new_status}, "error": None}
