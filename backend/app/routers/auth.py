from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from app.database import get_supabase
from app.config import Settings, get_settings
from app.models.auth import (
    ForceLogoutRequest,
    LoginRequest,
    RegisterStudentRequest,
    RegisterTeacherRequest,
    SessionValidation,
    TokenResponse,
)
from app.utils.security import (
    create_access_token,
    get_current_user,
    hash_password,
    require_role,
    verify_password,
)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, settings: Settings = Depends(get_settings)):
    db = get_supabase()

    if body.user_type == "admin":
        if body.email != "Admin@gmail.com" or body.password != "Admin@#1234":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid admin credentials")

        token = create_access_token(
            {"sub": "admin", "user_type": "admin", "user_name": "Admin", "user_email": "admin@local"},
            settings,
        )
        return TokenResponse(
            access_token=token,
            user_id="admin",
            user_type="admin",
            user_name="Admin",
            user_email="admin@local",
        )

    if body.user_type == "super_admin":
        result = db.table("super_admins").select("*").eq("email", body.email).eq("is_active", True).execute()
        user = result.data[0] if result.data else None
    elif body.user_type == "institution_admin":
        result = db.table("institution_admins").select("*").eq("email", body.email).eq("is_active", True).execute()
        user = result.data[0] if result.data else None
    elif body.user_type == "teacher":
        result = db.table("teachers").select("*").eq("email", body.email).eq("is_active", True).execute()
        user = result.data[0] if result.data else None
    elif body.user_type == "student":
        result = db.table("students").select("*").eq("email", body.email).eq("is_active", True).execute()
        user = result.data[0] if result.data else None
    else:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid user type")

    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if not verify_password(body.password, user["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid password")

    now_iso = datetime.now(timezone.utc).isoformat()
    if body.user_type == "teacher":
        db.table("teachers").update({"last_login": now_iso}).eq("id", user["id"]).execute()
    elif body.user_type == "student":
        db.table("students").update({"last_login": now_iso}).eq("id", user["id"]).execute()
    elif body.user_type == "super_admin":
        db.table("super_admins").update({"last_login": now_iso}).eq("id", user["id"]).execute()
    elif body.user_type == "institution_admin":
        db.table("institution_admins").update({"last_login": now_iso}).eq("id", user["id"]).execute()

    token = create_access_token(
        {
            "sub": user["id"],
            "user_type": body.user_type,
            "user_name": user.get("name", ""),
            "user_email": user.get("email", ""),
            "institution_id": user.get("institution_id", ""),
        },
        settings,
    )

    return TokenResponse(
        access_token=token,
        user_id=user["id"],
        user_type=body.user_type,
        user_name=user.get("name", ""),
        user_email=user.get("email", body.email),
        institution_id=user.get("institution_id"),
        cohort_id=user.get("cohort_id"),
    )


@router.post("/register/student", status_code=status.HTTP_201_CREATED)
def register_student(body: RegisterStudentRequest):
    db = get_supabase()

    existing = db.table("students").select("id").eq("email", body.email).execute()
    if existing.data:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")

    student_name = f"{body.first_name} {body.last_name}"
    student_data = {
        "name": student_name,
        "email": body.email,
        "password_hash": hash_password(body.password),
        "institution_id": body.institution_id,
        "phone": body.phone,
        "date_of_birth": body.date_of_birth,
        "student_id": body.student_id,
        "is_active": True,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    result = db.table("students").insert(student_data).execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create student")

    return {"success": True, "message": "Student registered successfully", "student_id": result.data[0]["id"]}


@router.post("/register/teacher", status_code=status.HTTP_201_CREATED)
def register_teacher(
    body: RegisterTeacherRequest,
    current_user: dict = Depends(require_role("admin", "institution_admin", "super_admin")),
):
    db = get_supabase()

    existing = db.table("teachers").select("id").eq("email", body.email).eq("institution_id", body.institution_id).execute()
    if existing.data:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered at this institution")

    teacher_data = {
        "name": body.name,
        "email": body.email,
        "password_hash": hash_password(body.password),
        "institution_id": body.institution_id,
        "subject": body.subject,
        "is_active": True,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    result = db.table("teachers").insert(teacher_data).execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create teacher")

    return {"success": True, "message": "Teacher registered successfully", "teacher_id": result.data[0]["id"]}


@router.post("/logout")
def logout(current_user: dict = Depends(get_current_user)):
    return {
        "success": True,
        "message": "Logged out successfully",
        "logout_timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/validate-session", response_model=SessionValidation)
def validate_session(current_user: dict = Depends(get_current_user)):
    return SessionValidation(
        valid=True,
        user_id=current_user["user_id"],
        user_type=current_user["user_type"],
        user_name=current_user["user_name"],
        user_email=current_user["user_email"],
    )


@router.post("/force-logout")
def force_logout(
    body: ForceLogoutRequest,
    current_user: dict = Depends(require_role("admin", "super_admin")),
):
    return {"success": True, "message": f"User {body.user_id} logged out successfully"}
