from fastapi import APIRouter
from app.services import institution_service

router = APIRouter(prefix="/api/public", tags=["Public"])

@router.get("/institutions")
def list_public_institutions():
    data = institution_service.list_institutions()
    return {"success": True, "data": data, "error": None}
