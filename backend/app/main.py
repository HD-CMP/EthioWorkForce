from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from loguru import logger
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1 import api_router
from app.middleware.logging import LoggingMiddleware
from app.middleware.error_handler import ErrorHandlerMiddleware
from app.middleware.security_headers import SecurityHeadersMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting EthioWorkforce API Server...")
    try:
        import sys
        from pathlib import Path
        backend_dir = Path(__file__).parent.parent
        if str(backend_dir) not in sys.path:
            sys.path.insert(0, str(backend_dir))
        
        from scripts.init_cloud_db import run_alembic_migrations, seed_cloud_database
        run_alembic_migrations()
        seed_cloud_database()
        logger.info("Database schema and master data initialized successfully.")
    except Exception as e:
        logger.error(f"Automatic database migration/seed notice: {e}")
    yield
    logger.info("Shutting down EthioWorkforce API Server...")


def create_application() -> FastAPI:
    if settings.SENTRY_DSN:
        sentry_sdk.init(
            dsn=settings.SENTRY_DSN,
            integrations=[FastApiIntegration()],
            environment=settings.ENVIRONMENT,
            traces_sample_rate=0.1,
        )

    show_docs = settings.ENABLE_DOCS or settings.ENVIRONMENT != "production"

    application = FastAPI(
        title="EthioWorkforce API",
        description="Offline-First Workforce Control, Attendance & Payroll System",
        version="1.0.0",
        docs_url="/api/docs" if show_docs else None,
        redoc_url="/api/redoc" if show_docs else None,
        lifespan=lifespan,
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    application.add_middleware(GZipMiddleware, minimum_size=1000)
    application.add_middleware(SecurityHeadersMiddleware)
    application.add_middleware(LoggingMiddleware)
    application.add_middleware(ErrorHandlerMiddleware)

    application.include_router(api_router, prefix="/api/v1")

    import os
    from fastapi.staticfiles import StaticFiles
    os.makedirs("uploads/id_cards", exist_ok=True)
    os.makedirs("uploads/avatars", exist_ok=True)
    application.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

    @application.get("/")
    async def root():
        return {
            "name": "EthioWorkforce API",
            "version": "1.0.0",
            "status": "operational",
            "environment": settings.ENVIRONMENT,
            "docs": "/api/docs" if show_docs else None,
            "health": "/health",
        }

    @application.get("/health")
    async def health_check():
        return {"status": "healthy", "service": "ethioworkforce-api"}

    return application


app = create_application()
