from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    secret_key: str = "change-me-to-a-random-64-char-string"
    jwt_algorithm: str = "HS256"
    jwt_expire_hours: int = 8

    supabase_url: str = "https://placeholder.supabase.co"
    supabase_key: str = "placeholder-key"

    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_use_tls: bool = True
    smtp_sender_email: str = "noreply@digikul.in"

    cors_origins: str = "http://localhost:3000,http://localhost:8000"

    upload_folder: str = "uploads"
    compressed_folder: str = "compressed"
    recording_directory: str = "recordings"

    enable_recording: bool = True
    enable_email_notifications: bool = True
    enable_quiz_analytics: bool = True
    enable_cohort_scoping: bool = True

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
