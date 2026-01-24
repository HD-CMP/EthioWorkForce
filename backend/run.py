import uvicorn
from app.core.logging_config import configure_logging

if __name__ == "__main__":
    configure_logging()
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
