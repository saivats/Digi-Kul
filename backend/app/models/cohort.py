from pydantic import BaseModel, Field


class CreateCohortRequest(BaseModel):
    name: str = Field(min_length=1)
    description: str | None = None
    enrollment_code: str = Field(min_length=3)
    max_students: int = 50
    academic_year: str | None = None
    semester: str | None = None
    start_date: str | None = None
    end_date: str | None = None


class JoinCohortRequest(BaseModel):
    enrollment_code: str = Field(min_length=3)


class AssignStudentRequest(BaseModel):
    student_id: str


class AssignTeacherRequest(BaseModel):
    teacher_id: str
