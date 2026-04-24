from fastapi import APIRouter, Depends, HTTPException, status

from app.models.quiz import AddQuestionRequest, BulkSubmitRequest, CreateQuizSetRequest, SubmitResponseRequest
from app.services import quiz_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/quizzes", tags=["Quizzes"])


@router.post("/sets", status_code=status.HTTP_201_CREATED)
def create_quiz_set(
    body: CreateQuizSetRequest,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    institution_id = current_user["institution_id"]
    if not institution_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No institution context")

    data = quiz_service.create_quiz_set(
        institution_id=institution_id,
        cohort_id=body.cohort_id,
        teacher_id=current_user["user_id"],
        title=body.title,
        description=body.description,
        time_limit=body.time_limit,
        max_attempts=body.max_attempts,
        starts_at=body.starts_at,
        ends_at=body.ends_at,
    )
    if not data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create quiz set")
    return {"success": True, "data": data, "error": None}


@router.get("/sets/cohort/{cohort_id}")
def list_quiz_sets(cohort_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = quiz_service.list_quiz_sets_for_cohort(cohort_id, institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/sets/{quiz_set_id}")
def get_quiz_set(quiz_set_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = quiz_service.get_quiz_set(quiz_set_id, institution_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz set not found")
    return {"success": True, "data": data, "error": None}


@router.delete("/sets/{quiz_set_id}")
def delete_quiz_set(
    quiz_set_id: str,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    institution_id = current_user["institution_id"]
    success = quiz_service.delete_quiz_set(quiz_set_id, institution_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz set not found")
    return {"success": True, "data": {"deleted": True}, "error": None}


@router.post("/sets/{quiz_set_id}/questions", status_code=status.HTTP_201_CREATED)
def add_question(
    quiz_set_id: str,
    body: AddQuestionRequest,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    data = quiz_service.add_question(
        quiz_set_id=quiz_set_id,
        question_text=body.question_text,
        question_type=body.question_type,
        options=body.options,
        correct_answer=body.correct_answer,
        explanation=body.explanation,
        points=body.points,
        order_index=body.order_index,
    )
    if not data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to add question")
    return {"success": True, "data": data, "error": None}


@router.get("/sets/{quiz_set_id}/questions")
def list_questions(quiz_set_id: str, current_user: dict = Depends(get_current_user)):
    data = quiz_service.get_questions(quiz_set_id)
    if current_user["user_type"] == "student":
        data = [
            {k: v for k, v in q.items() if k not in ("correct_answer", "explanation")}
            for q in data
        ]
    return {"success": True, "data": data, "error": None}


@router.delete("/questions/{question_id}")
def delete_question(
    question_id: str,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    success = quiz_service.delete_question(question_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question not found")
    return {"success": True, "data": {"deleted": True}, "error": None}


@router.post("/attempts/{quiz_set_id}/start", status_code=status.HTTP_201_CREATED)
def start_attempt(
    quiz_set_id: str,
    current_user: dict = Depends(require_role("student")),
):
    data = quiz_service.start_attempt(current_user["user_id"], quiz_set_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to start attempt")
    return {"success": True, "data": data, "error": None}


@router.post("/attempts/{attempt_id}/submit")
def submit_response(
    attempt_id: str,
    body: SubmitResponseRequest,
    current_user: dict = Depends(require_role("student")),
):
    data = quiz_service.submit_response(
        attempt_id=attempt_id,
        quiz_id=body.quiz_id,
        student_id=current_user["user_id"],
        selected_answer=body.selected_answer,
    )
    return {"success": True, "data": data, "error": None}


@router.post("/attempts/{attempt_id}/submit-bulk")
def submit_bulk_responses(
    attempt_id: str,
    body: BulkSubmitRequest,
    current_user: dict = Depends(require_role("student")),
):
    results = []
    for response in body.responses:
        result = quiz_service.submit_response(
            attempt_id=attempt_id,
            quiz_id=response.quiz_id,
            student_id=current_user["user_id"],
            selected_answer=response.selected_answer,
        )
        results.append(result)
    return {"success": True, "data": results, "error": None}


@router.post("/attempts/{attempt_id}/complete")
def complete_attempt(
    attempt_id: str,
    current_user: dict = Depends(require_role("student")),
):
    data = quiz_service.complete_attempt(attempt_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attempt not found")
    return {"success": True, "data": data, "error": None}


@router.get("/attempts/{attempt_id}")
def get_attempt(attempt_id: str, current_user: dict = Depends(get_current_user)):
    data = quiz_service.get_attempt(attempt_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attempt not found")
    return {"success": True, "data": data, "error": None}


@router.get("/sets/{quiz_set_id}/attempts")
def list_attempts(
    quiz_set_id: str,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    data = quiz_service.get_quiz_attempts_for_set(quiz_set_id)
    return {"success": True, "data": data, "error": None}


@router.get("/history")
def student_quiz_history(current_user: dict = Depends(require_role("student"))):
    data = quiz_service.get_student_quiz_history(current_user["user_id"])
    return {"success": True, "data": data, "error": None}
