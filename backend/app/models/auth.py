from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    user_type: str = Field(pattern="^(teacher|student|admin|super_admin|institution_admin)$")


class RegisterStudentRequest(BaseModel):
    first_name: str = Field(min_length=1)
    last_name: str = Field(min_length=1)
    email: EmailStr
    password: str = Field(min_length=6)
    institution_id: str
    phone: str | None = None
    date_of_birth: str | None = None
    gender: str | None = None
    address: str | None = None
    grade: str | None = None
    student_id: str | None = None
    parent_name: str | None = None
    parent_email: str | None = None
    parent_phone: str | None = None


class RegisterTeacherRequest(BaseModel):
    name: str = Field(min_length=1)
    email: EmailStr
    password: str = Field(min_length=6)
    institution_id: str
    subject: str = Field(min_length=1)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    user_type: str
    user_name: str
    user_email: str
    institution_id: str | None = None
    cohort_id: str | None = None


class SessionValidation(BaseModel):
    valid: bool
    user_id: str | None = None
    user_type: str | None = None
    user_name: str | None = None
    user_email: str | None = None


class ForceLogoutRequest(BaseModel):
    user_id: str
