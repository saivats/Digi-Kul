from pydantic import BaseModel, Field


class CreateLectureRequest(BaseModel):
    cohort_id: str
    title: str = Field(min_length=1)
    description: str | None = None
    scheduled_time: str
    duration: int = Field(default=60, gt=0)


class UpdateLectureRequest(BaseModel):
    title: str | None = None
    description: str | None = None
    scheduled_time: str | None = None
    duration: int | None = None
    status: str | None = None
