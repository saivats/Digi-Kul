from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.database import get_supabase
from app.services import (
    attendance_service,
    cohort_service,
    device_service,
    lecture_service,
    material_service,
    quiz_service,
    recording_service,
)
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/students", tags=["Students"])


def _ok(data):
    return {"success": True, "data": data, "error": None}


def _student_cohort_ids(current_user: dict) -> list[str]:
    institution_id = current_user.get("institution_id") or ""
    return [c["id"] for c in cohort_service.get_student_cohorts(current_user["user_id"], institution_id)]


class StartAttemptRequest(BaseModel):
    quiz_set_id: str


class SubmitAttemptRequest(BaseModel):
    # {question_id: selected option key OR option text}
    answers: dict[str, str] = Field(default_factory=dict)


class QuizResponseRequest(BaseModel):
    attempt_id: str
    question_id: str
    response: str


class FcmTokenRequest(BaseModel):
    token: str = Field(min_length=10)
    platform: str | None = None


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


# ---------------------------------------------------------------------------
# Student-scoped aggregate endpoints (consumed by the Flutter app and the web
# student dashboard). All are scoped to the caller's own enrolments.
# ---------------------------------------------------------------------------

@router.get("/profile")
def get_profile_alias(current_user: dict = Depends(require_role("student"))):
    """Alias of /me (the mobile client's name for it)."""
    return get_profile(current_user)


@router.patch("/profile")
def update_profile_alias(updates: dict, current_user: dict = Depends(require_role("student"))):
    return update_profile(updates, current_user)


@router.get("/dashboard")
def dashboard(current_user: dict = Depends(require_role("student"))):
    """Everything the student home screen needs in one round-trip."""
    institution_id = current_user.get("institution_id") or ""
    db = get_supabase()
    prof = db.table("students").select("id, name, email, student_id, avatar_url, institution_id").eq(
        "id", current_user["user_id"]
    ).execute()
    profile = prof.data[0] if prof.data else {"id": current_user["user_id"], "name": current_user["user_name"]}

    cohorts = cohort_service.get_student_cohorts(current_user["user_id"], institution_id)
    cohort_ids = [c["id"] for c in cohorts]
    lectures = lecture_service.list_lectures_for_cohorts(cohort_ids, institution_id)
    live = [l for l in lectures if l.get("status") == "live"]
    upcoming = sorted(
        [l for l in lectures if l.get("status") == "scheduled"],
        key=lambda l: l.get("scheduled_time") or "",
    )[:5]
    history = quiz_service.get_student_quiz_history(current_user["user_id"])[:5]
    attendance = attendance_service.list_for_student(current_user["user_id"], institution_id)
    return _ok({
        "profile": profile,
        "cohorts": cohorts,
        "live_lecture": live[0] if live else None,
        "live_lectures": live,
        "upcoming_lectures": upcoming,
        "recent_quiz_attempts": history,
        "attendance": attendance_service.summary(attendance),
        "counts": {
            "cohorts": len(cohorts),
            "lectures": len(lectures),
            "quizzes_taken": len(history),
        },
    })


@router.get("/lectures")
def my_lectures(current_user: dict = Depends(require_role("student"))):
    institution_id = current_user.get("institution_id") or ""
    return _ok(lecture_service.list_lectures_for_cohorts(_student_cohort_ids(current_user), institution_id))


@router.get("/lectures/upcoming")
def my_upcoming_lectures(current_user: dict = Depends(require_role("student"))):
    institution_id = current_user.get("institution_id") or ""
    lectures = lecture_service.list_lectures_for_cohorts(_student_cohort_ids(current_user), institution_id)
    upcoming = [l for l in lectures if l.get("status") == "scheduled"]
    upcoming.sort(key=lambda l: l.get("scheduled_time") or "")
    return _ok(upcoming)


@router.get("/lectures/live")
def my_live_lectures(current_user: dict = Depends(require_role("student"))):
    institution_id = current_user.get("institution_id") or ""
    lectures = lecture_service.list_lectures_for_cohorts(_student_cohort_ids(current_user), institution_id)
    return _ok([l for l in lectures if l.get("status") == "live"])


@router.get("/materials")
def my_materials(current_user: dict = Depends(require_role("student"))):
    institution_id = current_user.get("institution_id") or ""
    return _ok(material_service.list_materials_for_cohorts(_student_cohort_ids(current_user), institution_id))


@router.get("/recordings")
def my_recordings(current_user: dict = Depends(require_role("student"))):
    institution_id = current_user.get("institution_id") or ""
    return _ok(recording_service.list_recordings_for_cohorts(_student_cohort_ids(current_user), institution_id))


@router.get("/attendance")
def my_attendance(current_user: dict = Depends(require_role("student"))):
    institution_id = current_user.get("institution_id") or ""
    records = attendance_service.list_for_student(current_user["user_id"], institution_id)
    return {"success": True, "data": records, "summary": attendance_service.summary(records), "error": None}


@router.post("/fcm-token")
def register_fcm_token(body: FcmTokenRequest, current_user: dict = Depends(require_role("student"))):
    try:
        data = device_service.register_token(
            student_id=current_user["user_id"],
            institution_id=current_user.get("institution_id") or "",
            token=body.token,
            platform=body.platform,
        )
    except Exception as exc:  # table missing until the migration is applied
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Device registry unavailable (apply migrations/20260912_create_student_devices.sql): {exc}",
        ) from exc
    return _ok({"registered": True, "id": data.get("id")})


@router.delete("/fcm-token")
def unregister_fcm_token(body: FcmTokenRequest, current_user: dict = Depends(require_role("student"))):
    device_service.remove_token(student_id=current_user["user_id"], token=body.token)
    return _ok({"registered": False})


# ---- quizzes ---------------------------------------------------------------

@router.get("/quizzes")
def my_quizzes(current_user: dict = Depends(require_role("student"))):
    institution_id = current_user.get("institution_id") or ""
    return _ok(
        quiz_service.list_quiz_sets_for_student(
            current_user["user_id"], _student_cohort_ids(current_user), institution_id
        )
    )


def _assert_quiz_in_my_cohorts(quiz_set_id: str, current_user: dict) -> dict:
    institution_id = current_user.get("institution_id") or ""
    quiz_set = quiz_service.get_quiz_set(quiz_set_id, institution_id)
    if not quiz_set or quiz_set.get("cohort_id") not in _student_cohort_ids(current_user):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz not found")
    return quiz_set


@router.get("/quizzes/{quiz_set_id}/questions")
def my_quiz_questions(quiz_set_id: str, current_user: dict = Depends(require_role("student"))):
    _assert_quiz_in_my_cohorts(quiz_set_id, current_user)
    return _ok(quiz_service.get_questions_for_student(quiz_set_id))


@router.post("/quiz-attempts", status_code=status.HTTP_201_CREATED)
def start_quiz_attempt(body: StartAttemptRequest, current_user: dict = Depends(require_role("student"))):
    quiz_set = _assert_quiz_in_my_cohorts(body.quiz_set_id, current_user)
    shaped = quiz_service.shape_quiz_set_for_student(quiz_set, 0)
    if shaped["status"] in ("expired", "upcoming"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Quiz is {shaped['status']}")
    max_attempts = quiz_set.get("max_attempts") or 0
    if max_attempts:
        done = [
            a for a in quiz_service.get_quiz_attempts_for_set(body.quiz_set_id)
            if a.get("student_id") == current_user["user_id"] and a.get("is_completed")
        ]
        if len(done) >= max_attempts:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No attempts left for this quiz")
    attempt = quiz_service.start_attempt(current_user["user_id"], body.quiz_set_id)
    if not attempt:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to start attempt")
    attempt["status"] = "in_progress"
    return {"success": True, "data": attempt, "attempt_id": attempt["id"], "error": None}


def _my_attempt(attempt_id: str, current_user: dict) -> dict:
    attempt = quiz_service.get_attempt(attempt_id)
    if not attempt or attempt.get("student_id") != current_user["user_id"]:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attempt not found")
    return attempt


@router.get("/quiz-attempts/{attempt_id}/questions")
def attempt_questions(attempt_id: str, current_user: dict = Depends(require_role("student"))):
    attempt = _my_attempt(attempt_id, current_user)
    return _ok(quiz_service.get_questions_for_student(attempt["quiz_set_id"]))


@router.post("/quiz-attempts/{attempt_id}/submit")
def submit_quiz_attempt(
    attempt_id: str,
    body: SubmitAttemptRequest,
    current_user: dict = Depends(require_role("student")),
):
    attempt = _my_attempt(attempt_id, current_user)
    if attempt.get("is_completed"):
        # Idempotent for offline retries: return the stored result.
        return _ok(quiz_service.get_attempt_result(attempt_id, current_user["user_id"]))
    result = quiz_service.submit_answers_and_complete(
        attempt_id=attempt_id, student_id=current_user["user_id"], answers=body.answers
    )
    if not result:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attempt not found")
    return _ok(result)


@router.get("/quiz-attempts/{attempt_id}/result")
def quiz_attempt_result(attempt_id: str, current_user: dict = Depends(require_role("student"))):
    _my_attempt(attempt_id, current_user)
    return _ok(quiz_service.get_attempt_result(attempt_id, current_user["user_id"]))


@router.post("/quiz-responses")
def submit_single_response(body: QuizResponseRequest, current_user: dict = Depends(require_role("student"))):
    """Record one answer (used for autosave); grading happens on submit."""
    _my_attempt(body.attempt_id, current_user)
    data = quiz_service.submit_response(
        attempt_id=body.attempt_id,
        quiz_id=body.question_id,
        student_id=current_user["user_id"],
        selected_answer=body.response,
    )
    return _ok(data)


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
