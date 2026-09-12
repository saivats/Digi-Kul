from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    secret_key: str = "change-me-to-a-random-64-char-string"
    jwt_algorithm: str = "HS256"
    jwt_expire_hours: int = 8

    supabase_url: str = "https://placeholder.supabase.co"
    supabase_key: str = "placeholder-key"

    # Redis backs the live-session store and Socket.IO's cross-process
    # message queue. Every uvicorn worker / container replica must point at
    # the same instance. docker-compose provides the `redis` service.
    redis_url: str = "redis://localhost:6379/0"

    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_use_tls: bool = True
    smtp_sender_email: str = "noreply@digikul.in"

    # Shared by the REST CORSMiddleware AND the Socket.IO server.
    cors_origins: str = (
        "http://localhost,http://localhost:80,"
        "http://localhost:3000,http://localhost:8000,"
        "http://127.0.0.1,http://127.0.0.1:80,"
        "http://127.0.0.1:3000,http://127.0.0.1:8000"
    )

    upload_folder: str = "uploads"
    compressed_folder: str = "compressed"
    recording_directory: str = "recordings"
    max_recording_duration: int = 7200

    enable_recording: bool = True
    enable_email_notifications: bool = True
    enable_quiz_analytics: bool = True
    enable_cohort_scoping: bool = True

    # Socket.IO per-connection throttles (events per second, burst size).
    socket_chat_rate: float = 5.0
    socket_chat_burst: int = 10
    socket_stroke_rate: float = 60.0
    socket_stroke_burst: int = 120

    # Seconds a live-session record lives in Redis without being touched.
    session_ttl_seconds: int = 6 * 60 * 60

    log_level: str = "INFO"
    log_file: str = "app.log"

    # `extra="ignore"` so deployment-only keys in .env (ADMIN_EMAIL, etc.)
    # don't crash startup with "Extra inputs are not permitted".
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
