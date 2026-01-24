from app.tasks import celery_app
from loguru import logger


@celery_app.task(name="generate_payroll_report")
def generate_payroll_report(payroll_id: int) -> dict:
    logger.info(f"Generating payroll report for payroll_id: {payroll_id}")
    return {"status": "success", "payroll_id": payroll_id}


@celery_app.task(name="export_payment_file")
def export_payment_file(payroll_id: int, format: str) -> dict:
    logger.info(f"Exporting payment file for payroll_id: {payroll_id}, format: {format}")
    return {"status": "success", "payroll_id": payroll_id, "format": format}
