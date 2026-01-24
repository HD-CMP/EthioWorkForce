from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from typing import Dict
from pydantic import BaseModel

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.worker import Worker
from app.models.attendance import Attendance
from app.models.payroll import Payroll, PayrollItem
from app.models.site import Site
from app.services.sneakernet_sync import SneakernetSyncService

router = APIRouter()
sync_service = SneakernetSyncService()


class SneakernetExportRequest(BaseModel):
    site_id: int
    encryption_password: str
    include_workers: bool = True
    include_attendances: bool = True
    include_payrolls: bool = True


class SneakernetImportRequest(BaseModel):
    package: Dict
    encryption_password: str
    merge_strategy: str = "server_wins"


@router.post("/sneakernet/export")
def export_sneakernet_package(
    request: SneakernetExportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Export data package for offline sneakernet synchronization
    
    Creates encrypted, checksummed package for USB transfer to offline sites
    """
    site = db.query(Site).filter(Site.id == request.site_id).first()
    if not site:
        raise HTTPException(status_code=404, detail="Site not found")
    
    workers_data = []
    attendances_data = []
    payrolls_data = []
    
    if request.include_workers:
        workers = db.query(Worker).filter(Worker.site_id == request.site_id).all()
        workers_data = [
            {
                "id": w.id,
                "employee_id": w.employee_id,
                "full_name": w.full_name,
                "phone_number": w.phone_number,
                "work_type_id": w.work_type_id,
                "site_id": w.site_id,
                "status": w.status.value,
                "calendar_preference": w.calendar_preference.value,
                "bank_name": w.bank_name,
                "bank_account_number": w.bank_account_number,
                "qr_code": w.qr_code,
                "created_at": w.created_at.isoformat() if w.created_at else None,
                "updated_at": w.updated_at.isoformat() if w.updated_at else None
            }
            for w in workers
        ]
    
    if request.include_attendances:
        attendances = db.query(Attendance).filter(
            Attendance.site_id == request.site_id
        ).all()
        attendances_data = [
            {
                "id": a.id,
                "worker_id": a.worker_id,
                "site_id": a.site_id,
                "attendance_date": a.attendance_date.isoformat(),
                "status": a.status.value,
                "method": a.method.value,
                "regular_hours": a.regular_hours,
                "overtime_hours": a.overtime_hours,
                "is_verified": a.is_verified,
                "is_locked": a.is_locked,
                "created_at": a.created_at.isoformat() if a.created_at else None,
                "updated_at": a.updated_at.isoformat() if a.updated_at else None
            }
            for a in attendances
        ]
    
    if request.include_payrolls:
        payrolls = db.query(Payroll).filter(Payroll.site_id == request.site_id).all()
        for payroll in payrolls:
            payroll_items = db.query(PayrollItem).filter(
                PayrollItem.payroll_id == payroll.id
            ).all()
            
            payrolls_data.append({
                "id": payroll.id,
                "payroll_code": payroll.payroll_code,
                "site_id": payroll.site_id,
                "period_start": payroll.period_start.isoformat(),
                "period_end": payroll.period_end.isoformat(),
                "status": payroll.status.value,
                "total_gross_amount": str(payroll.total_gross_amount),
                "total_deductions": str(payroll.total_deductions),
                "total_net_amount": str(payroll.total_net_amount),
                "items": [
                    {
                        "id": item.id,
                        "worker_id": item.worker_id,
                        "days_worked": item.days_worked,
                        "gross_salary": str(item.gross_salary),
                        "net_salary": str(item.net_salary),
                        "income_tax": str(item.income_tax),
                        "employee_pension": str(item.employee_pension)
                    }
                    for item in payroll_items
                ],
                "created_at": payroll.created_at.isoformat() if payroll.created_at else None,
                "updated_at": payroll.updated_at.isoformat() if payroll.updated_at else None
            })
    
    package = sync_service.export_sneakernet_package(
        site_id=request.site_id,
        site_code=site.code,
        workers=workers_data,
        attendances=attendances_data,
        payrolls=payrolls_data,
        encryption_password=request.encryption_password
    )
    
    return {
        "success": True,
        "package": package,
        "message": f"Sneakernet package created for site {site.code}"
    }


@router.post("/sneakernet/import")
def import_sneakernet_package(
    request: SneakernetImportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Import encrypted sneakernet package from offline site
    
    Decrypts, validates, and merges data with conflict resolution
    """
    validation_report = sync_service.validate_package_integrity(request.package)
    
    if not validation_report["valid"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Package validation failed: {validation_report['errors']}"
        )
    
    try:
        payload = sync_service.import_sneakernet_package(
            request.package,
            request.encryption_password
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    site_id = payload["site_id"]
    
    local_workers = db.query(Worker).filter(Worker.site_id == site_id).all()
    local_workers_data = [
        {
            "id": w.id,
            "employee_id": w.employee_id,
            "updated_at": w.updated_at.isoformat() if w.updated_at else None
        }
        for w in local_workers
    ]
    
    imported_workers = payload["data"]["workers"]
    
    merge_result = sync_service.merge_with_conflict_resolution(
        local_workers_data,
        imported_workers,
        strategy=request.merge_strategy
    )
    
    return {
        "success": True,
        "site_id": site_id,
        "site_code": payload["site_code"],
        "imported_at": payload["exported_at"],
        "validation": validation_report,
        "merge_summary": {
            "total_records": merge_result["total_records"],
            "new_records": merge_result["new_records"],
            "updated_records": merge_result["updated_records"],
            "conflicts": merge_result["conflicts"]
        },
        "message": f"Sneakernet import completed for site {payload['site_code']}"
    }


@router.post("/sneakernet/validate")
def validate_sneakernet_package(
    package: Dict = Body(...),
):
    """
    Validate sneakernet package integrity without importing
    
    Checks structure, version compatibility, and data freshness
    """
    validation_report = sync_service.validate_package_integrity(package)
    
    return {
        "valid": validation_report["valid"],
        "errors": validation_report["errors"],
        "warnings": validation_report["warnings"],
        "package_info": {
            "site_code": package.get("site_code"),
            "exported_at": package.get("exported_at"),
            "version": package.get("package_version"),
            "record_counts": package.get("record_counts")
        }
    }
