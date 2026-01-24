from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, PostgresDsn


class FreeTierSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    DATABASE_URL: PostgresDsn = Field(
        default="postgresql://postgres:password@localhost:5432/ethioworkforce"
    )

    SECRET_KEY: str = Field(min_length=32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    ENVIRONMENT: str = "production"
    DEBUG: bool = False

    CORS_ORIGINS: List[str] = Field(
        default=["*"]
    )

    LOG_LEVEL: str = "WARNING"

    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_SIZE: int = 5242880
    
    MAX_WORKERS: int = 2
    
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 2
    DB_POOL_TIMEOUT: int = 30
    DB_POOL_RECYCLE: int = 300
    
    REQUEST_TIMEOUT: int = 30
    
    ENABLE_REDIS: bool = False
    ENABLE_CELERY: bool = False
    
    CACHE_TTL: int = 300
    
    BATCH_SIZE: int = 100
    
    ENABLE_COMPRESSION: bool = True
    
    MAX_CONCURRENT_REQUESTS: int = 10

    @property
    def database_url_str(self) -> str:
        return str(self.DATABASE_URL)

    @property
    def uvicorn_config(self) -> dict:
        return {
            "host": "0.0.0.0",
            "port": 8000,
            "workers": self.MAX_WORKERS,
            "timeout_keep_alive": 30,
            "limit_concurrency": self.MAX_CONCURRENT_REQUESTS,
            "limit_max_requests": 1000,
            "backlog": 64,
        }


free_tier_settings = FreeTierSettings()
