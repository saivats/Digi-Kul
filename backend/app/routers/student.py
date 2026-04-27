from fastapi import APIRouter, Depends, HTTPException, status

from app.database import get_supabase
from app.services import cohort_service, quiz_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/students", tags=["Students"])


@router.get("/me")
def get_profile(current_user: dict = Depends(require_role("student"))):
    db = get_supabase()
    result = db.table("students").select("*").eq("id", current_user["user_id"]).execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
    student = result.data[0]
    student.pop("password_hash", None)
    return {"success": True, "data": student, "error": None}


@router.patch("/me")
def update_profile(
    updates: dict,
    current_user: dict = Depends(require_role("student")),
):
    db = get_supabase()
    safe_fields = {"phone", "avatar_url", "date_of_birth"}
    filtered = {k: v for k, v in updates.items() if k in safe_fields}
    if not filtered:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No updatable fields provided")
    result = db.table("students").update(filtered).eq("id", current_user["user_id"]).execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
    student = result.data[0]
    student.pop("password_hash", None)
    return {"success": True, "data": student, "error": None}


@router.get("/cohorts")
def my_cohorts(current_user: dict = Depends(require_role("student"))):
    institution_id = current_user["institution_id"]
    data = cohort_service.get_student_cohorts(current_user["user_id"], institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/quiz-history")
def quiz_history(current_user: dict = Depends(require_role("student"))):
    data = quiz_service.get_student_quiz_history(current_user["user_id"])
    return {"success": True, "data": data, "error": None}


@router.get("")
def list_students(
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin", "teacher")),
):
    db = get_supabase()
    institution_id = current_user.get("institution_id")
    
    query = db.table("students").select("id, name, email, student_id, phone, is_active, created_at, last_login").order("name")
    
    if current_user["user_type"] not in ("super_admin", "admin"):
        if not institution_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No institution context")
        query = query.eq("institution_id", institution_id)
        
    result = query.execute()
    return {"success": True, "data": result.data or [], "error": None}


@router.get("/{student_id}")
def get_student(
    student_id: str,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin", "teacher")),
):
    db = get_supabase()
    institution_id = current_user["institution_id"]
    result = (
        db.table("students")
        .select("id, name, email, student_id, phone, is_active, created_at, last_login")
        .eq("id", student_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
    return {"success": True, "data": result.data[0], "error": None}


@router.post("/{student_id}/toggle-active")
def toggle_active(
    student_id: str,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin")),
):
    db = get_supabase()
    institution_id = current_user["institution_id"]
    student = (
        db.table("students")
        .select("is_active")
        .eq("id", student_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    if not student.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
    new_status = not student.data[0]["is_active"]
    db.table("students").update({"is_active": new_status}).eq("id", student_id).execute()
    return {"success": True, "data": {"is_active": new_status}, "error": None}
