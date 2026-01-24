from typing import List, Union
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator
import os


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    DATABASE_URL: str = Field(
        default="postgresql://postgres:password@localhost:5432/ethioworkforce"
    )
    DATABASE_URL_TEST: str = Field(
        default="postgresql://postgres:password@localhost:5432/ethioworkforce_test"
    )

    SECRET_KEY: str = Field(min_length=32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    REDIS_URL: str = "redis://localhost:6379/0"

    ENVIRONMENT: str = "development"

    CORS_ORIGINS: Union[List[str], str] = Field(
        default=["http://localhost:3000", "http://localhost:8080"]
    )

    @field_validator('CORS_ORIGINS', mode='before')
    @classmethod
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            if v == "*":
                return ["*"]
            return [origin.strip() for origin in v.split(',') if origin.strip()]
        return v

    SENTRY_DSN: str = ""

    LOG_LEVEL: str = "INFO"

    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_SIZE: int = 10485760

    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    @property
    def database_url_str(self) -> str:
        url = str(self.DATABASE_URL)
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql://", 1)
        return url


settings = Settings()
