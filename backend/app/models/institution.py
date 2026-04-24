from pydantic import BaseModel, EmailStr, Field


class CreateInstitutionRequest(BaseModel):
    name: str = Field(min_length=1)
    domain: str = Field(min_length=3)
    subdomain: str | None = None
    description: str | None = None
    contact_email: EmailStr | None = None
    contact_phone: str | None = None
    address: str | None = None
    website: str | None = None
    primary_color: str = "#007bff"


class UpdateInstitutionRequest(BaseModel):
    name: str | None = None
    description: str | None = None
    contact_email: EmailStr | None = None
    contact_phone: str | None = None
    address: str | None = None
    website: str | None = None
    primary_color: str | None = None
    is_active: bool | None = None
