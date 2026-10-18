from app.tasks import celery_app
from loguru import logger


@celery_app.task(name="sync_offline_data")
def sync_offline_data(site_id: int, data_payload: dict) -> dict:
    logger.info(f"Syncing offline data for site_id: {site_id}")
    return {"status": "success", "site_id": site_id}


@celery_app.task(name="process_sneakernet_import")
def process_sneakernet_import(file_path: str) -> dict:
    logger.info(f"Processing sneakernet import from: {file_path}")
    return {"status": "success", "file_path": file_path}
