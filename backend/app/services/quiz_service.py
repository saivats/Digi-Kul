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
    question = db.table("quizzes").select("correct_answer, points, options").eq("id", quiz_id).execute()
    is_correct = False
    points_earned = 0
    if question.data:
        is_correct = is_answer_correct(question.data[0], selected_answer)
        points_earned = (question.data[0].get("points") or 1) if is_correct else 0

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


# ---------------------------------------------------------------------------
# Student-facing helpers (used by /api/students/quizzes* and the web client)
# ---------------------------------------------------------------------------

def normalize_options(options) -> list[dict]:
    """quizzes.options is JSONB and has been written in several shapes:
    {"a": "Paris", "b": "Rome"}  |  ["Paris", "Rome"]  |  [{"key": "a", "text": "Paris"}]
    Return a uniform ordered list of {key, text}."""
    if not options:
        return []
    if isinstance(options, dict):
        return [{"key": str(k), "text": str(v)} for k, v in options.items()]
    out = []
    for i, item in enumerate(options):
        if isinstance(item, dict):
            key = str(item.get("key") or item.get("id") or item.get("value") or chr(97 + i))
            text = str(item.get("text") or item.get("label") or item.get("option") or "")
        else:
            key, text = chr(97 + i), str(item)
        out.append({"key": key, "text": text})
    return out


def is_answer_correct(question: dict, selected: str | None) -> bool:
    """Accept either the option key ("a") or the option text ("Paris")."""
    if selected is None:
        return False
    correct = question.get("correct_answer")
    if correct is None:
        return False
    sel = str(selected).strip().lower()
    cor = str(correct).strip().lower()
    if sel == cor:
        return True
    for opt in normalize_options(question.get("options")):
        if opt["key"].lower() == cor and opt["text"].strip().lower() == sel:
            return True
        if opt["text"].strip().lower() == cor and opt["key"].lower() == sel:
            return True
    return False


def shape_question_for_student(q: dict) -> dict:
    """Strip answers and present options as a plain list of strings (what the
    mobile client renders). Keys are preserved in `option_keys` so a client can
    submit either form."""
    opts = normalize_options(q.get("options"))
    return {
        "id": q["id"],
        "quiz_set_id": q.get("quiz_set_id"),
        "question": q.get("question_text", ""),
        "question_text": q.get("question_text", ""),
        "question_type": "mcq" if q.get("question_type") in (None, "multiple_choice", "mcq") else q.get("question_type"),
        "options": [o["text"] for o in opts],
        "option_keys": [o["key"] for o in opts],
        "points": q.get("points", 1),
        "order_index": q.get("order_index", 0),
    }


def _question_count(db, quiz_set_id: str) -> int:
    res = db.table("quizzes").select("id", count="exact").eq("quiz_set_id", quiz_set_id).execute()
    return res.count if res.count is not None else len(res.data or [])


def shape_quiz_set_for_student(qs: dict, question_count: int, attempts_used: int = 0) -> dict:
    from datetime import datetime, timezone

    now = datetime.now(timezone.utc)

    def _parse(v):
        if not v:
            return None
        try:
            d = datetime.fromisoformat(str(v).replace("Z", "+00:00"))
            return d if d.tzinfo else d.replace(tzinfo=timezone.utc)
        except ValueError:
            return None

    starts, ends = _parse(qs.get("starts_at")), _parse(qs.get("ends_at"))
    if not qs.get("is_active", True):
        status = "expired"
    elif starts and starts > now:
        status = "upcoming"
    elif ends and ends < now:
        status = "expired"
    elif qs.get("max_attempts") and attempts_used >= qs["max_attempts"]:
        status = "completed"
    else:
        status = "available"
    return {
        **qs,
        "description": qs.get("description") or "",
        "question_count": question_count,
        "time_limit_seconds": (qs["time_limit"] * 60) if qs.get("time_limit") else None,
        "available_from": qs.get("starts_at") or qs.get("created_at"),
        "available_until": qs.get("ends_at"),
        "attempts_used": attempts_used,
        "status": status,
    }


def list_quiz_sets_for_student(student_id: str, cohort_ids: list[str], institution_id: str) -> list[dict]:
    if not cohort_ids:
        return []
    db = get_supabase()
    sets = (
        db.table("quiz_sets")
        .select("*")
        .in_("cohort_id", cohort_ids)
        .eq("institution_id", institution_id)
        .eq("is_active", True)
        .order("created_at", desc=True)
        .execute()
        .data
        or []
    )
    if not sets:
        return []
    set_ids = [q["id"] for q in sets]
    questions = db.table("quizzes").select("quiz_set_id").in_("quiz_set_id", set_ids).execute().data or []
    counts: dict[str, int] = {}
    for q in questions:
        counts[q["quiz_set_id"]] = counts.get(q["quiz_set_id"], 0) + 1
    attempts = (
        db.table("quiz_attempts")
        .select("quiz_set_id, is_completed")
        .eq("student_id", student_id)
        .in_("quiz_set_id", set_ids)
        .execute()
        .data
        or []
    )
    used: dict[str, int] = {}
    for a in attempts:
        if a.get("is_completed"):
            used[a["quiz_set_id"]] = used.get(a["quiz_set_id"], 0) + 1
    return [shape_quiz_set_for_student(qs, counts.get(qs["id"], 0), used.get(qs["id"], 0)) for qs in sets]


def get_questions_for_student(quiz_set_id: str) -> list[dict]:
    return [shape_question_for_student(q) for q in get_questions(quiz_set_id)]


def submit_answers_and_complete(*, attempt_id: str, student_id: str, answers: dict[str, str]) -> dict | None:
    """Grade a whole attempt at once ({question_id: answer}), record each
    response, mark the attempt complete and return the result with a
    per-question review."""
    db = get_supabase()
    attempt = get_attempt(attempt_id)
    if not attempt or attempt.get("student_id") != student_id:
        return None
    questions = get_questions(attempt["quiz_set_id"])
    # Replace any partial responses from an earlier (offline-retried) submit.
    db.table("quiz_responses").delete().eq("attempt_id", attempt_id).execute()

    now = datetime.now(timezone.utc).isoformat()
    rows, review = [], []
    for q in questions:
        selected = answers.get(q["id"])
        correct = is_answer_correct(q, selected)
        rows.append({
            "attempt_id": attempt_id,
            "quiz_id": q["id"],
            "student_id": student_id,
            "selected_answer": selected,
            "is_correct": correct,
            "points_earned": (q.get("points") or 1) if correct else 0,
            "responded_at": now,
        })
        opts = normalize_options(q.get("options"))
        key_to_text = {o["key"]: o["text"] for o in opts}
        review.append({
            "question_id": q["id"],
            "question": q.get("question_text", ""),
            "options": [o["text"] for o in opts],
            "selected_answer": key_to_text.get(str(selected), selected) if selected is not None else None,
            "correct_answer": key_to_text.get(str(q.get("correct_answer")), q.get("correct_answer")),
            "is_correct": correct,
            "explanation": q.get("explanation"),
        })
    if rows:
        db.table("quiz_responses").insert(rows).execute()

    total = len(questions)
    correct_count = sum(1 for r in rows if r["is_correct"])
    score = sum(r["points_earned"] for r in rows)
    time_spent = None
    try:
        started = datetime.fromisoformat(str(attempt["started_at"]).replace("Z", "+00:00"))
        time_spent = max(0, int((datetime.now(timezone.utc) - started).total_seconds()))
    except (KeyError, ValueError, TypeError):
        pass
    updated = (
        db.table("quiz_attempts")
        .update({
            "is_completed": True,
            "finished_at": now,
            "total_questions": total,
            "correct_answers": correct_count,
            "score": score,
            "time_spent": time_spent,
        })
        .eq("id", attempt_id)
        .execute()
    )
    attempt = updated.data[0] if updated.data else {**attempt, "total_questions": total, "correct_answers": correct_count}

    quiz_set = db.table("quiz_sets").select("show_correct_answers").eq("id", attempt["quiz_set_id"]).execute()
    show = True if not quiz_set.data else quiz_set.data[0].get("show_correct_answers", True)
    if not show:
        for r in review:
            r.pop("correct_answer", None)
            r.pop("explanation", None)
    return build_result(attempt, review)


def build_result(attempt: dict, review: list[dict] | None = None) -> dict:
    total = attempt.get("total_questions") or 0
    correct = attempt.get("correct_answers") or 0
    return {
        "attempt_id": attempt["id"],
        "quiz_set_id": attempt.get("quiz_set_id"),
        "total_questions": total,
        "correct_answers": correct,
        "score": attempt.get("score") or 0,
        "score_percentage": round(correct / total * 100, 1) if total else 0.0,
        "time_taken_seconds": attempt.get("time_spent"),
        "is_completed": attempt.get("is_completed", False),
        "finished_at": attempt.get("finished_at"),
        "review": review or [],
    }


def get_attempt_result(attempt_id: str, student_id: str) -> dict | None:
    db = get_supabase()
    attempt = get_attempt(attempt_id)
    if not attempt or attempt.get("student_id") != student_id:
        return None
    responses = db.table("quiz_responses").select("*").eq("attempt_id", attempt_id).execute().data or []
    by_q = {r["quiz_id"]: r for r in responses}
    review = []
    for q in get_questions(attempt["quiz_set_id"]):
        r = by_q.get(q["id"])
        opts = normalize_options(q.get("options"))
        key_to_text = {o["key"]: o["text"] for o in opts}
        sel = (r or {}).get("selected_answer")
        review.append({
            "question_id": q["id"],
            "question": q.get("question_text", ""),
            "options": [o["text"] for o in opts],
            "selected_answer": key_to_text.get(str(sel), sel) if sel is not None else None,
            "correct_answer": key_to_text.get(str(q.get("correct_answer")), q.get("correct_answer")),
            "is_correct": bool((r or {}).get("is_correct")),
            "explanation": q.get("explanation"),
        })
    return build_result(attempt, review)
