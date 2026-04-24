from fastapi import APIRouter, Depends, HTTPException, status

from app.models.institution import CreateInstitutionRequest, UpdateInstitutionRequest
from app.services import institution_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/institutions", tags=["Institutions"])


@router.get("")
def list_institutions(
    current_user: dict = Depends(require_role("super_admin", "admin")),
):
    data = institution_service.list_institutions()
    return {"success": True, "data": data, "error": None}


@router.post("", status_code=status.HTTP_201_CREATED)
def create_institution(
    body: CreateInstitutionRequest,
    current_user: dict = Depends(require_role("super_admin", "admin")),
):
    data = institution_service.create_institution(
        name=body.name,
        domain=body.domain,
        subdomain=body.subdomain,
        description=body.description,
        contact_email=body.contact_email,
        contact_phone=body.contact_phone,
        address=body.address,
        website=body.website,
        primary_color=body.primary_color,
        created_by=current_user["user_id"],
    )
    if not data:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create institution")
    return {"success": True, "data": data, "error": None}


@router.get("/{institution_id}")
def get_institution(
    institution_id: str,
    current_user: dict = Depends(get_current_user),
):
    data = institution_service.get_institution(institution_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution not found")
    return {"success": True, "data": data, "error": None}


@router.patch("/{institution_id}")
def update_institution(
    institution_id: str,
    body: UpdateInstitutionRequest,
    current_user: dict = Depends(require_role("super_admin", "admin", "institution_admin")),
):
    updates = body.model_dump(exclude_none=True)
    if not updates:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")
    data = institution_service.update_institution(institution_id, updates)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution not found")
    return {"success": True, "data": data, "error": None}


@router.delete("/{institution_id}")
def deactivate_institution(
    institution_id: str,
    current_user: dict = Depends(require_role("super_admin", "admin")),
):
    success = institution_service.deactivate_institution(institution_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution not found")
    return {"success": True, "data": {"deactivated": True}, "error": None}


@router.get("/{institution_id}/stats")
def get_institution_stats(
    institution_id: str,
    current_user: dict = Depends(get_current_user),
):
    data = institution_service.get_institution_stats(institution_id)
    return {"success": True, "data": data, "error": None}
