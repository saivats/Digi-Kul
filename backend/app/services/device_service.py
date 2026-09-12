"""Push-notification device tokens (FCM).

Requires the `student_devices` table — see
migrations/20260912_create_student_devices.sql.
"""

from datetime import datetime, timezone

from app.database import get_supabase


def register_token(*, student_id: str, institution_id: str, token: str, platform: str | None) -> dict:
    db = get_supabase()
    now = datetime.now(timezone.utc).isoformat()
    payload = {
        "student_id": student_id,
        "institution_id": institution_id or None,
        "fcm_token": token,
        "platform": platform or "android",
        "updated_at": now,
    }
    result = db.table("student_devices").upsert(payload, on_conflict="fcm_token").execute()
    return result.data[0] if result.data else payload


def remove_token(*, student_id: str, token: str) -> None:
    db = get_supabase()
    db.table("student_devices").delete().eq("student_id", student_id).eq("fcm_token", token).execute()
