from fastapi import APIRouter, Depends, HTTPException, status

from app.services import institution_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/super-admin", tags=["Super Admin"])


@router.get("/platform-stats")
def platform_stats(
    current_user: dict = Depends(require_role("super_admin", "admin")),
):
    data = institution_service.get_platform_stats()
    return {"success": True, "data": data, "error": None}


@router.get("/institutions")
def list_all_institutions(
    current_user: dict = Depends(require_role("super_admin", "admin")),
):
    data = institution_service.list_institutions(is_active=None)
    return {"success": True, "data": data, "error": None}


@router.post("/institutions/{institution_id}/toggle")
def toggle_institution(
    institution_id: str,
    current_user: dict = Depends(require_role("super_admin", "admin")),
):
    inst = institution_service.get_institution(institution_id)
    if not inst:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution not found")

    new_status = not inst.get("is_active", True)
    updated = institution_service.update_institution(institution_id, {"is_active": new_status})
    return {"success": True, "data": updated, "error": None}
