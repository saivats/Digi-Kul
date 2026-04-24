from datetime import datetime, timezone

from app.database import get_supabase


def create_quiz_set(
    *,
    institution_id: str,
    cohort_id: str,
    teacher_id: str,
    title: str,
    description: str | None = None,
    time_limit: int | None = None,
    max_attempts: int = 1,
    starts_at: str | None = None,
    ends_at: str | None = None,
) -> dict:
    db = get_supabase()
    payload = {
        "institution_id": institution_id,
        "cohort_id": cohort_id,
        "teacher_id": teacher_id,
        "title": title,
        "description": description,
        "time_limit": time_limit,
        "max_attempts": max_attempts,
        "starts_at": starts_at,
        "ends_at": ends_at,
        "is_active": True,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("quiz_sets").insert(payload).execute()
    return result.data[0] if result.data else {}


def get_quiz_set(quiz_set_id: str, institution_id: str) -> dict | None:
    db = get_supabase()
    result = (
        db.table("quiz_sets")
        .select("*")
        .eq("id", quiz_set_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None


def list_quiz_sets_for_cohort(cohort_id: str, institution_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("quiz_sets")
        .select("*")
        .eq("cohort_id", cohort_id)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("created_at", desc=True)
        .execute()
        .data
        or []
    )


def update_quiz_set(quiz_set_id: str, institution_id: str, updates: dict) -> dict | None:
    db = get_supabase()
    result = (
        db.table("quiz_sets")
        .update(updates)
        .eq("id", quiz_set_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return result.data[0] if result.data else None


def delete_quiz_set(quiz_set_id: str, institution_id: str) -> bool:
    db = get_supabase()
    result = (
        db.table("quiz_sets")
        .update({"is_active": False})
        .eq("id", quiz_set_id)
        .eq("institution_id", institution_id)
        .execute()
    )
    return bool(result.data)


def add_question(
    *,
    quiz_set_id: str,
    question_text: str,
    question_type: str = "multiple_choice",
    options: dict | list | None = None,
    correct_answer: str | None = None,
    explanation: str | None = None,
    points: int = 1,
    order_index: int = 0,
) -> dict:
    db = get_supabase()
    payload = {
        "quiz_set_id": quiz_set_id,
        "question_text": question_text,
        "question_type": question_type,
        "options": options,
        "correct_answer": correct_answer,
        "explanation": explanation,
        "points": points,
        "order_index": order_index,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("quizzes").insert(payload).execute()
    return result.data[0] if result.data else {}


def get_questions(quiz_set_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("quizzes")
        .select("*")
        .eq("quiz_set_id", quiz_set_id)
        .order("order_index")
        .execute()
        .data
        or []
    )


def update_question(question_id: str, updates: dict) -> dict | None:
    db = get_supabase()
    result = db.table("quizzes").update(updates).eq("id", question_id).execute()
    return result.data[0] if result.data else None


def delete_question(question_id: str) -> bool:
    db = get_supabase()
    result = db.table("quizzes").delete().eq("id", question_id).execute()
    return bool(result.data)


def start_attempt(student_id: str, quiz_set_id: str) -> dict:
    db = get_supabase()
    existing = (
        db.table("quiz_attempts")
        .select("attempt_number")
        .eq("student_id", student_id)
        .eq("quiz_set_id", quiz_set_id)
        .order("attempt_number", desc=True)
        .limit(1)
        .execute()
    )
    next_attempt = (existing.data[0]["attempt_number"] + 1) if existing.data else 1

    payload = {
        "student_id": student_id,
        "quiz_set_id": quiz_set_id,
        "attempt_number": next_attempt,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "is_completed": False,
    }
    result = db.table("quiz_attempts").insert(payload).execute()
    return result.data[0] if result.data else {}


def get_attempt(attempt_id: str) -> dict | None:
    db = get_supabase()
    result = db.table("quiz_attempts").select("*").eq("id", attempt_id).execute()
    return result.data[0] if result.data else None


def submit_response(
    *,
    attempt_id: str,
    quiz_id: str,
    student_id: str,
    selected_answer: str,
) -> dict:
    db = get_supabase()
    question = db.table("quizzes").select("correct_answer, points").eq("id", quiz_id).execute()
    is_correct = False
    points_earned = 0
    if question.data:
        is_correct = question.data[0]["correct_answer"] == selected_answer
        points_earned = question.data[0]["points"] if is_correct else 0

    payload = {
        "attempt_id": attempt_id,
        "quiz_id": quiz_id,
        "student_id": student_id,
        "selected_answer": selected_answer,
        "is_correct": is_correct,
        "points_earned": points_earned,
        "responded_at": datetime.now(timezone.utc).isoformat(),
    }
    result = db.table("quiz_responses").insert(payload).execute()
    return result.data[0] if result.data else {}


def complete_attempt(attempt_id: str) -> dict | None:
    db = get_supabase()
    responses = (
        db.table("quiz_responses")
        .select("is_correct, points_earned")
        .eq("attempt_id", attempt_id)
        .execute()
        .data
        or []
    )
    total = len(responses)
    correct = sum(1 for r in responses if r["is_correct"])
    score = sum(r["points_earned"] for r in responses)

    updates = {
        "is_completed": True,
        "finished_at": datetime.now(timezone.utc).isoformat(),
        "total_questions": total,
        "correct_answers": correct,
        "score": score,
    }
    result = db.table("quiz_attempts").update(updates).eq("id", attempt_id).execute()
    return result.data[0] if result.data else None


def get_quiz_attempts_for_set(quiz_set_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("quiz_attempts")
        .select("*")
        .eq("quiz_set_id", quiz_set_id)
        .order("started_at", desc=True)
        .execute()
        .data
        or []
    )


def get_student_quiz_history(student_id: str) -> list[dict]:
    db = get_supabase()
    return (
        db.table("quiz_attempts")
        .select("*, quiz_sets(title, description, cohort_id)")
        .eq("student_id", student_id)
        .order("started_at", desc=True)
        .execute()
        .data
        or []
    )
