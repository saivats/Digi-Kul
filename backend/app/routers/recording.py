from fastapi import APIRouter, Depends, HTTPException, status

from app.services import recording_service
from app.utils.security import get_current_user, require_role

router = APIRouter(prefix="/api/recordings", tags=["Recordings"])


@router.get("/lecture/{lecture_id}")
def list_by_lecture(lecture_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = recording_service.list_recordings_for_lecture(lecture_id, institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/cohort/{cohort_id}")
def list_by_cohort(cohort_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = recording_service.list_recordings_for_cohort(cohort_id, institution_id)
    return {"success": True, "data": data, "error": None}


@router.get("/{recording_id}")
def get_recording(recording_id: str, current_user: dict = Depends(get_current_user)):
    institution_id = current_user["institution_id"]
    data = recording_service.get_recording(recording_id, institution_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")
    return {"success": True, "data": data, "error": None}


@router.post("/{recording_id}/download")
def track_download(recording_id: str, current_user: dict = Depends(get_current_user)):
    recording_service.increment_download_count(recording_id)
    return {"success": True, "data": {"tracked": True}, "error": None}


@router.delete("/{recording_id}")
def delete_recording(
    recording_id: str,
    current_user: dict = Depends(require_role("teacher", "institution_admin", "admin")),
):
    institution_id = current_user["institution_id"]
    success = recording_service.delete_recording(recording_id, institution_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")
    return {"success": True, "data": {"deleted": True}, "error": None}
