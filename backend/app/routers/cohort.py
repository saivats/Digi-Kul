from fastapi import APIRouter, Depends, HTTPException, status

from app.models.cohort import (
    AssignStudentRequest,
    AssignTeacherRequest,
    CreateCohortRequest,
    JoinCohortRequest,
)
from app.services import cohort_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/cohorts", tags=["Cohorts"])


@router.get("")
def list_cohorts(current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    if not institution_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No institution context")

    if current_user["user_type"] == "teacher":
        data = cohort_service.get_teacher_cohorts(current_user["user_id"], institution_id)
    elif current_user["user_type"] == "student":
        data = cohort_service.get_student_cohorts(current_user["user_id"], institution_id)
    else:
        data = cohort_service.list_cohorts_for_institution(institution_id)
    return {"success": True, "data": data, "error": None}


@router.post("", status_code=status.HTTP_201_CREATED)
def create_cohort(
    body: CreateCohortRequest,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin")),
):
    institution_id = current_user["institution_id"]
    if not institution_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No institution context")

    data = cohort_service.create_cohort(
        institution_id=institution_id,
        name=body.name,
        description=body.description,
        enrollment_code=body.enrollment_code,
        max_students=body.max_students,
        academic_year=body.academic_year,
        semester=body.semester,
        start_date=body.start_date,
        end_date=body.end_date,
        created_by=current_user["user_id"],
    )
    if not data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create cohort")
    return {"success": True, "data": data, "error": None}


@router.get("/{cohort_id}")
def get_cohort(cohort_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = cohort_service.get_cohort(cohort_id, institution_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cohort not found")
    return {"success": True, "data": data, "error": None}


@router.delete("/{cohort_id}")
def delete_cohort(
    cohort_id: str,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin")),
):
    institution_id = current_user["institution_id"]
    success = cohort_service.delete_cohort(cohort_id, institution_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cohort not found")
    return {"success": True, "data": {"deleted": True}, "error": None}


@router.get("/{cohort_id}/students")
def get_cohort_students(cohort_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = cohort_service.get_cohort_students(cohort_id, institution_id)
    return {"success": True, "data": data, "error": None}


@router.post("/{cohort_id}/students")
def add_student(
    cohort_id: str,
    body: AssignStudentRequest,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin", "teacher")),
):
    institution_id = current_user["institution_id"]
    data = cohort_service.add_student_to_cohort(cohort_id, body.student_id, institution_id)
    return {"success": True, "data": data, "error": None}


@router.delete("/{cohort_id}/students/{student_id}")
def remove_student(
    cohort_id: str,
    student_id: str,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin")),
):
    institution_id = current_user["institution_id"]
    success = cohort_service.remove_student_from_cohort(cohort_id, student_id, institution_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Enrollment not found")
    return {"success": True, "data": {"removed": True}, "error": None}


@router.post("/join")
def join_cohort(
    body: JoinCohortRequest,
    current_user: dict = Depends(require_role("student")),
):
    institution_id = current_user["institution_id"]
    cohort = cohort_service.join_cohort_by_code(current_user["user_id"], body.enrollment_code, institution_id)
    if not cohort:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid enrollment code")
    return {"success": True, "data": cohort, "error": None}


@router.post("/{cohort_id}/teachers")
def assign_teacher(
    cohort_id: str,
    body: AssignTeacherRequest,
    current_user: dict = Depends(require_role("institution_admin", "admin", "super_admin")),
):
    institution_id = current_user["institution_id"]
    data = cohort_service.assign_teacher_to_cohort(cohort_id, body.teacher_id, institution_id)
    return {"success": True, "data": data, "error": None}
