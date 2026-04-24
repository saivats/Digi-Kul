from fastapi import APIRouter, Depends, HTTPException, status

from app.models.lecture import CreateLectureRequest, UpdateLectureRequest
from app.services import lecture_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/lectures", tags=["Lectures"])


@router.post("", status_code=status.HTTP_201_CREATED)
def create_lecture(
    body: CreateLectureRequest,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin", "super_admin")),
):
    institution_id = current_user["institution_id"]
    if not institution_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No institution context")

    data = lecture_service.create_lecture(
        institution_id=institution_id,
        cohort_id=body.cohort_id,
        teacher_id=current_user["user_id"],
        title=body.title,
        description=body.description,
        scheduled_time=body.scheduled_time,
        duration=body.duration,
    )
    if not data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create lecture")
    return {"success": True, "data": data, "error": None}


@router.get("")
def list_lectures(current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    if current_user["user_type"] == "teacher":
        data = lecture_service.list_lectures_for_teacher(current_user["user_id"], institution_id)
    else:
        data = lecture_service.get_active_lectures(institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/cohort/{cohort_id}")
def list_lectures_by_cohort(cohort_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = lecture_service.list_lectures_for_cohort(cohort_id, institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/{lecture_id}")
def get_lecture(lecture_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = lecture_service.get_lecture(lecture_id, institution_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found")
    return {"success": True, "data": data, "error": None}


@router.patch("/{lecture_id}")
def update_lecture(
    lecture_id: str,
    body: UpdateLectureRequest,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    institution_id = current_user["institution_id"]
    updates = body.model_dump(exclude_none=True)
    if not updates:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")
    data = lecture_service.update_lecture(lecture_id, institution_id, updates)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found")
    return {"success": True, "data": data, "error": None}


@router.delete("/{lecture_id}")
def delete_lecture(
    lecture_id: str,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    institution_id = current_user["institution_id"]
    success = lecture_service.delete_lecture(lecture_id, institution_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found")
    return {"success": True, "data": {"deleted": True}, "error": None}


@router.post("/{lecture_id}/start")
def start_lecture(
    lecture_id: str,
    current_user: dict = Depends(require_role("teacher")),
):
    institution_id = current_user["institution_id"]
    data = lecture_service.set_lecture_status(lecture_id, institution_id, "live")
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found")
    return {"success": True, "data": data, "error": None}


@router.post("/{lecture_id}/end")
def end_lecture(
    lecture_id: str,
    current_user: dict = Depends(require_role("teacher")),
):
    institution_id = current_user["institution_id"]
    data = lecture_service.set_lecture_status(lecture_id, institution_id, "ended")
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lecture not found")
    return {"success": True, "data": data, "error": None}
