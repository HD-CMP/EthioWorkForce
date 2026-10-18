from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime

from app.core.database import get_db
from app.api.deps import get_current_user, verify_site_access
from app.core.ethiopian_calendar import EthiopianCalendar
from app.models.user import User
from app.models.overtime import Overtime
from app.models.worker import Worker
from app.schemas.overtime import (
    OvertimeCreate,
    OvertimeUpdate,
    OvertimeResponse,
    OvertimeBulkCreate,
    OvertimeEntry,
    OvertimeVerify,
    MultiDayOvertimeCreate
)

router = APIRouter()


@router.get("/", response_model=List[OvertimeResponse])
def get_overtimes(
    site_id: int,
    worker_id: Optional[int] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    is_verified: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, site_id, db):
        raise HTTPException(status_code=403, detail="You don't have access to this site")
    
    query = db.query(Overtime).filter(Overtime.site_id == site_id)
    
    if worker_id:
        query = query.filter(Overtime.worker_id == worker_id)
    if date_from:
        query = query.filter(Overtime.overtime_date >= date_from)
    if date_to:
        query = query.filter(Overtime.overtime_date <= date_to)
    if is_verified is not None:
        query = query.filter(Overtime.is_verified == is_verified)
    
    overtimes = query.order_by(Overtime.overtime_date.desc()).all()
    
    result = []
    for overtime in overtimes:
        worker = db.query(Worker).filter(Worker.id == overtime.worker_id).first()
        result.append({
            "id": overtime.id,
            "worker_id": overtime.worker_id,
            "worker_name": worker.full_name if worker else None,
            "employee_id": worker.employee_id if worker else None,
            "site_id": overtime.site_id,
            "overtime_date": overtime.overtime_date,
            "hours": overtime.hours,
            "is_verified": overtime.is_verified,
            "verified_by_id": overtime.verified_by_id,
            "verified_at": overtime.verified_at,
            "is_locked": overtime.is_locked,
            "notes": overtime.notes,
            "ethiopian_date_year": overtime.ethiopian_date_year,
            "ethiopian_date_month": overtime.ethiopian_date_month,
            "ethiopian_date_day": overtime.ethiopian_date_day,
            "created_at": overtime.created_at,
            "updated_at": overtime.updated_at,
        })
    
    return result


@router.post("/", response_model=OvertimeResponse)
def create_overtime(
    overtime_data: OvertimeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, overtime_data.site_id, db):
        raise HTTPException(status_code=403, detail="You don't have access to this site")
    
    worker = db.query(Worker).filter(Worker.id == overtime_data.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
        
    if not worker.work_type or not worker.work_type.overtime_eligible:
        raise HTTPException(status_code=400, detail=f"Worker {worker.full_name} is not eligible for overtime")
    
    
    existing = db.query(Overtime).filter(
        Overtime.worker_id == overtime_data.worker_id,
        Overtime.site_id == overtime_data.site_id,
        Overtime.overtime_date == overtime_data.overtime_date
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Overtime record already exists for this date")
    
    eth_year, eth_month, eth_day = EthiopianCalendar.gregorian_to_ethiopian(overtime_data.overtime_date)
    
    overtime = Overtime(
        worker_id=overtime_data.worker_id,
        site_id=overtime_data.site_id,
        overtime_date=overtime_data.overtime_date,
        hours=overtime_data.hours,
        notes=overtime_data.notes,
        ethiopian_date_year=eth_year,
        ethiopian_date_month=eth_month,
        ethiopian_date_day=eth_day,
    )
    
    db.add(overtime)
    db.commit()
    db.refresh(overtime)
    
    return {
        "id": overtime.id,
        "worker_id": overtime.worker_id,
        "worker_name": worker.full_name,
        "employee_id": worker.employee_id,
        "site_id": overtime.site_id,
        "overtime_date": overtime.overtime_date,
        "hours": overtime.hours,
        "is_verified": overtime.is_verified,
        "verified_by_id": overtime.verified_by_id,
        "verified_at": overtime.verified_at,
        "is_locked": overtime.is_locked,
        "notes": overtime.notes,
        "ethiopian_date_year": overtime.ethiopian_date_year,
        "ethiopian_date_month": overtime.ethiopian_date_month,
        "ethiopian_date_day": overtime.ethiopian_date_day,
        "created_at": overtime.created_at,
        "updated_at": overtime.updated_at,
    }


@router.post("/bulk")
def create_bulk_overtime(
    bulk_data: OvertimeBulkCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, bulk_data.site_id, db):
        raise HTTPException(status_code=403, detail="You don't have access to this site")
    
    created_count = 0
    updated_count = 0
    errors = []
    
    for entry in bulk_data.entries:
        try:
            worker = db.query(Worker).filter(Worker.id == entry.worker_id).first()
            if not worker:
                errors.append(f"Worker ID {entry.worker_id} not found")
                continue
                
            if not worker.work_type or not worker.work_type.overtime_eligible:
                errors.append(f"Worker {worker.full_name} is not eligible for overtime")
                continue
            
            
            existing = db.query(Overtime).filter(
                Overtime.worker_id == entry.worker_id,
                Overtime.site_id == bulk_data.site_id,
                Overtime.overtime_date == bulk_data.overtime_date
            ).first()
            
            if existing:
                if entry.hours == 0:
                    db.delete(existing)
                    updated_count += 1
                else:
                    existing.hours = entry.hours
                    if bulk_data.verify:
                        existing.is_verified = True
                        existing.verified_by_id = current_user.id
                        existing.verified_at = datetime.utcnow()
                        existing.is_locked = True
                    updated_count += 1
            else:
                if entry.hours > 0:
                    eth_year, eth_month, eth_day = EthiopianCalendar.gregorian_to_ethiopian(bulk_data.overtime_date)
                    overtime = Overtime(
                        worker_id=entry.worker_id,
                        site_id=bulk_data.site_id,
                        overtime_date=bulk_data.overtime_date,
                        hours=entry.hours,
                        ethiopian_date_year=eth_year,
                        ethiopian_date_month=eth_month,
                        ethiopian_date_day=eth_day,
                    )
                    
                    if bulk_data.verify:
                        overtime.is_verified = True
                        overtime.verified_by_id = current_user.id
                        overtime.verified_at = datetime.utcnow()
                        overtime.is_locked = True
                    
                    db.add(overtime)
                    created_count += 1
        
        except Exception as e:
            errors.append(f"Error processing worker ID {entry.worker_id}: {str(e)}")
    
    db.commit()
    
    return {
        "created": created_count,
        "updated": updated_count,
        "errors": errors
    }


@router.post("/multi-day")
def create_multi_day_overtime(
    multi_data: MultiDayOvertimeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, multi_data.site_id, db):
        raise HTTPException(status_code=403, detail="You don't have access to this site")
    
    worker = db.query(Worker).filter(Worker.id == multi_data.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
        
    if not worker.work_type or not worker.work_type.overtime_eligible:
        raise HTTPException(status_code=400, detail=f"Worker {worker.full_name} is not eligible for overtime")
    
    created_count = 0
    updated_count = 0
    errors = []
    
    for entry in multi_data.entries:
        try:
            existing = db.query(Overtime).filter(
                Overtime.worker_id == multi_data.worker_id,
                Overtime.site_id == multi_data.site_id,
                Overtime.overtime_date == entry.overtime_date
            ).first()
            
            if existing:
                if existing.is_locked:
                    errors.append(f"Overtime on {entry.overtime_date} is locked")
                    continue
                    
                if entry.hours == 0:
                    db.delete(existing)
                    updated_count += 1
                else:
                    existing.hours = entry.hours
                    if multi_data.verify:
                        existing.is_verified = True
                        existing.verified_by_id = current_user.id
                        existing.verified_at = datetime.utcnow()
                        existing.is_locked = True
                    updated_count += 1
            else:
                if entry.hours > 0:
                    eth_year, eth_month, eth_day = EthiopianCalendar.gregorian_to_ethiopian(entry.overtime_date)
                    overtime = Overtime(
                        worker_id=multi_data.worker_id,
                        site_id=multi_data.site_id,
                        overtime_date=entry.overtime_date,
                        hours=entry.hours,
                        ethiopian_date_year=eth_year,
                        ethiopian_date_month=eth_month,
                        ethiopian_date_day=eth_day,
                    )
                    
                    if multi_data.verify:
                        overtime.is_verified = True
                        overtime.verified_by_id = current_user.id
                        overtime.verified_at = datetime.utcnow()
                        overtime.is_locked = True
                    
                    db.add(overtime)
                    created_count += 1
        
        except Exception as e:
            errors.append(f"Error processing date {entry.overtime_date}: {str(e)}")
    
    db.commit()
    
    return {
        "created": created_count,
        "updated": updated_count,
        "errors": errors
    }


@router.patch("/{overtime_id}", response_model=OvertimeResponse)
def update_overtime(
    overtime_id: int,
    overtime_data: OvertimeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    overtime = db.query(Overtime).filter(Overtime.id == overtime_id).first()
    if not overtime:
        raise HTTPException(status_code=404, detail="Overtime not found")
    
    if not verify_site_access(current_user, overtime.site_id, db):
        raise HTTPException(status_code=403, detail="You don't have access to this site")
        
    worker = db.query(Worker).filter(Worker.id == overtime.worker_id).first()
    if worker and (not worker.work_type or not worker.work_type.overtime_eligible):
        raise HTTPException(status_code=400, detail="This worker is not eligible for overtime")
    
    
    if overtime.is_locked:
        raise HTTPException(status_code=403, detail="Overtime is locked and cannot be modified")
    
    if overtime_data.hours is not None:
        overtime.hours = overtime_data.hours
    if overtime_data.notes is not None:
        overtime.notes = overtime_data.notes
    
    db.commit()
    db.refresh(overtime)
    
    worker = db.query(Worker).filter(Worker.id == overtime.worker_id).first()
    
    return {
        "id": overtime.id,
        "worker_id": overtime.worker_id,
        "worker_name": worker.full_name if worker else None,
        "employee_id": worker.employee_id if worker else None,
        "site_id": overtime.site_id,
        "overtime_date": overtime.overtime_date,
        "hours": overtime.hours,
        "is_verified": overtime.is_verified,
        "verified_by_id": overtime.verified_by_id,
        "verified_at": overtime.verified_at,
        "is_locked": overtime.is_locked,
        "notes": overtime.notes,
        "ethiopian_date_year": overtime.ethiopian_date_year,
        "ethiopian_date_month": overtime.ethiopian_date_month,
        "ethiopian_date_day": overtime.ethiopian_date_day,
        "created_at": overtime.created_at,
        "updated_at": overtime.updated_at,
    }


@router.delete("/{overtime_id}")
def delete_overtime(
    overtime_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    overtime = db.query(Overtime).filter(Overtime.id == overtime_id).first()
    if not overtime:
        raise HTTPException(status_code=404, detail="Overtime not found")
    
    if not verify_site_access(current_user, overtime.site_id, db):
        raise HTTPException(status_code=403, detail="You don't have access to this site")
    
    if overtime.is_locked:
        raise HTTPException(status_code=403, detail="Overtime is locked and cannot be deleted")
    
    db.delete(overtime)
    db.commit()
    
    return {"message": "Overtime deleted successfully"}


@router.post("/verify")
def verify_overtime(
    verify_data: OvertimeVerify,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, verify_data.site_id, db):
        raise HTTPException(status_code=403, detail="You don't have access to this site")
    
    verified_count = 0
    errors = []
    
    for overtime_id in verify_data.overtime_ids:
        try:
            overtime = db.query(Overtime).filter(Overtime.id == overtime_id).first()
            if not overtime:
                errors.append(f"Overtime ID {overtime_id} not found")
                continue
            
            overtime.is_verified = True
            overtime.verified_by_id = current_user.id
            overtime.verified_at = datetime.utcnow()
            overtime.is_locked = True
            verified_count += 1
        
        except Exception as e:
            errors.append(f"Error verifying overtime ID {overtime_id}: {str(e)}")
    
    db.commit()
    
    return {
        "verified": verified_count,
        "errors": errors
    }


@router.post("/unverify")
def unverify_overtime(
    verify_data: OvertimeVerify,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, verify_data.site_id, db):
        raise HTTPException(status_code=403, detail="You don't have access to this site")
    
    unverified_count = 0
    errors = []
    
    for overtime_id in verify_data.overtime_ids:
        try:
            overtime = db.query(Overtime).filter(Overtime.id == overtime_id).first()
            if not overtime:
                errors.append(f"Overtime ID {overtime_id} not found")
                continue
            
            overtime.is_verified = False
            overtime.verified_by_id = None
            overtime.verified_at = None
            overtime.is_locked = False
            unverified_count += 1
        
        except Exception as e:
            errors.append(f"Error unverifying overtime ID {overtime_id}: {str(e)}")
    
    db.commit()
    
    return {
        "unverified": unverified_count,
        "errors": errors
    }
