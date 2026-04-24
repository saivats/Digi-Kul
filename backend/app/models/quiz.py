from pydantic import BaseModel, Field


class CreateQuizSetRequest(BaseModel):
    cohort_id: str
    title: str = Field(min_length=1)
    description: str | None = None
    time_limit: int | None = None
    max_attempts: int = 1
    starts_at: str | None = None
    ends_at: str | None = None


class AddQuestionRequest(BaseModel):
    question_text: str = Field(min_length=1)
    question_type: str = "multiple_choice"
    options: dict | list | None = None
    correct_answer: str | None = None
    explanation: str | None = None
    points: int = 1
    order_index: int = 0


class SubmitResponseRequest(BaseModel):
    quiz_id: str
    selected_answer: str


class BulkSubmitRequest(BaseModel):
    responses: list[SubmitResponseRequest]
