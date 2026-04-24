import os
import uuid

from fastapi import APIRouter, Depends, HTTPException, UploadFile, status

from app.config import get_settings
from app.services import material_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/materials", tags=["Materials"])

ALLOWED_EXTENSIONS = {
    "images": {".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg"},
    "documents": {".pdf", ".doc", ".docx", ".ppt", ".pptx", ".xls", ".xlsx", ".txt"},
    "audio": {".mp3", ".wav", ".ogg", ".m4a"},
}


def _resolve_category(extension: str) -> str:
    for category, extensions in ALLOWED_EXTENSIONS.items():
        if extension.lower() in extensions:
            return category
    return "documents"


@router.post("", status_code=status.HTTP_201_CREATED)
async def upload_material(
    file: UploadFile,
    title: str = "",
    description: str = "",
    lecture_id: str | None = None,
    cohort_id: str | None = None,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    institution_id = current_user["institution_id"]
    if not institution_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No institution context")

    if not lecture_id and not cohort_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Provide lecture_id or cohort_id")

    extension = os.path.splitext(file.filename or "")[1]
    category = _resolve_category(extension)
    unique_name = f"{uuid.uuid4().hex}{extension}"
    settings = get_settings()
    save_dir = os.path.join(settings.upload_folder, category)
    os.makedirs(save_dir, exist_ok=True)
    save_path = os.path.join(save_dir, unique_name)

    content = await file.read()
    with open(save_path, "wb") as f:
        f.write(content)

    data = material_service.create_material(
        institution_id=institution_id,
        teacher_id=current_user["user_id"],
        title=title or file.filename or "Untitled",
        description=description,
        file_path=save_path,
        file_name=file.filename or unique_name,
        file_type=file.content_type or "application/octet-stream",
        file_size=len(content),
        lecture_id=lecture_id,
        cohort_id=cohort_id,
    )
    return {"success": True, "data": data, "error": None}


@router.get("/lecture/{lecture_id}")
def list_materials_for_lecture(lecture_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = material_service.list_materials_for_lecture(lecture_id, institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/cohort/{cohort_id}")
def list_materials_for_cohort(cohort_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = material_service.list_materials_for_cohort(cohort_id, institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/{material_id}")
def get_material(material_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = material_service.get_material(material_id, institution_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Material not found")
    return {"success": True, "data": data, "error": None}


@router.post("/{material_id}/download")
def track_download(material_id: str, current_user: dict = Depends(get_current_user)):
    material_service.increment_download_count(material_id)
    return {"success": True, "data": {"tracked": True}, "error": None}


@router.delete("/{material_id}")
def delete_material(
    material_id: str,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    institution_id = current_user["institution_id"]
    success = material_service.delete_material(material_id, institution_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Material not found")
    return {"success": True, "data": {"deleted": True}, "error": None}
