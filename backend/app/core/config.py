from typing import List, Union
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator
import os


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(".env", "backend/.env", os.path.join(os.path.dirname(__file__), "../../../.env"), os.path.join(os.path.dirname(__file__), "../../.env")),
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    DATABASE_URL: str = Field(
        default="postgresql+pg8000://localhost:5432/ethioworkforce"
    )
    DATABASE_URL_TEST: str = Field(
        default="postgresql+pg8000://localhost:5432/ethioworkforce_test"
    )

    SECRET_KEY: str = Field(
        default="1ba3a94233f9296246a932a1cce71325f35b7dd0d1015da72d5029714ab718b3",
        min_length=32
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    REDIS_URL: str = "redis://localhost:6379/0"

    ENVIRONMENT: str = "development"

    CORS_ORIGINS: Union[List[str], str] = Field(
        default=["*"]
    )

    @field_validator('CORS_ORIGINS', mode='before')
    @classmethod
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            if v == "*":
                return ["*"]
            return [origin.strip() for origin in v.split(',') if origin.strip()]
        return v

    ENABLE_DOCS: bool = True
    SENTRY_DSN: str = ""

    LOG_LEVEL: str = "INFO"

    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_SIZE: int = 10485760

    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    @property
    def is_ssl_required(self) -> bool:
        url = str(self.DATABASE_URL)
        return "sslmode=require" in url or "neon.tech" in url or "render.com" in url or "amazonaws.com" in url

    @property
    def database_url_str(self) -> str:
        """Return a normalized database URL string.
        Handles Heroku/Render/Neon/Supabase 'postgres://' shorthand and ensures
        pg8000 driver prefix is applied if psycopg2 is not specified.
        Strips 'sslmode' query parameter when using pg8000 since pg8000 uses
        connect_args ssl_context instead of sslmode keyword argument.
        """
        import re
        url = str(self.DATABASE_URL)
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql+pg8000://", 1)
        elif url.startswith("postgresql://") and not url.startswith("postgresql+"):
            url = url.replace("postgresql://", "postgresql+pg8000://", 1)

        if "pg8000" in url:
            url = re.sub(r'[\?&]sslmode=[^&]+', '', url)
            if '?' not in url and '&' in url:
                url = url.replace('&', '?', 1)
        return url

    @property
    def database_connect_args(self) -> dict:
        import ssl
        args = {}
        if "pg8000" in self.database_url_str and self.is_ssl_required:
            args["ssl_context"] = ssl.create_default_context()
        return args

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT.lower() == "production"


settings = Settings()

# Production safety checks (log warnings, don't crash)
if settings.is_production:
    import warnings
    _DEFAULT_KEY = "1ba3a94233f9296246a932a1cce71325f35b7dd0d1015da72d5029714ab718b3"
    if settings.SECRET_KEY == _DEFAULT_KEY:
        warnings.warn(
            "SECURITY WARNING: Using default SECRET_KEY in production! "
            "Set a unique SECRET_KEY environment variable.",
            stacklevel=2,
        )
    if ["*"] == settings.CORS_ORIGINS:
        warnings.warn(
            "SECURITY WARNING: CORS_ORIGINS is set to '*' in production. "
            "Consider restricting to specific domains.",
            stacklevel=2,
        )
