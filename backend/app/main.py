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


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting EthioWorkforce API Server...")
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

    application = FastAPI(
        title="EthioWorkforce API",
        description="Offline-First Workforce Control, Attendance & Payroll System",
        version="1.0.0",
        docs_url="/api/docs" if settings.ENVIRONMENT != "production" else None,
        redoc_url="/api/redoc" if settings.ENVIRONMENT != "production" else None,
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
    application.add_middleware(LoggingMiddleware)
    application.add_middleware(ErrorHandlerMiddleware)

    application.include_router(api_router, prefix="/api/v1")

    @application.get("/health")
    async def health_check():
        return {"status": "healthy", "service": "ethioworkforce-api"}

    return application


app = create_application()
