from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, date

from app.core.database import get_db
from app.api.deps import get_current_user, get_user_accessible_sites, verify_site_access
from app.core.ethiopian_calendar import EthiopianCalendar
from app.models.user import User, UserRole
from app.models.attendance import Attendance
from app.models.worker import Worker
from app.schemas.attendance import (
    AttendanceCreate,
    AttendanceBulkCreate,
    AttendanceUpdate,
    AttendanceVerify,
    AttendanceResponse
)

router = APIRouter()


@router.post("/", response_model=AttendanceResponse, status_code=status.HTTP_201_CREATED)
def create_attendance(
    attendance_data: AttendanceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, attendance_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    worker = db.query(Worker).filter(Worker.id == attendance_data.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    if worker.site_id != attendance_data.site_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Worker does not belong to this site"
        )
    
    existing = db.query(Attendance).filter(
        Attendance.worker_id == attendance_data.worker_id,
        Attendance.attendance_date == attendance_data.attendance_date
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Attendance already recorded for this worker on this date"
        )
    
    eth_date = EthiopianCalendar.gregorian_to_ethiopian(attendance_data.attendance_date)
    
    db_attendance = Attendance(
        **attendance_data.model_dump(),
        ethiopian_date_year=eth_date[0],
        ethiopian_date_month=eth_date[1],
        ethiopian_date_day=eth_date[2]
    )
    
    db.add(db_attendance)
    db.commit()
    db.refresh(db_attendance)
    return db_attendance


@router.post("/bulk", response_model=List[AttendanceResponse], status_code=status.HTTP_201_CREATED)
def create_bulk_attendance(
    bulk_data: AttendanceBulkCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, bulk_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    eth_date = EthiopianCalendar.gregorian_to_ethiopian(bulk_data.attendance_date)
    
    attendances = []
    for worker_id in bulk_data.worker_ids:
        worker = db.query(Worker).filter(Worker.id == worker_id).first()
        if not worker or worker.site_id != bulk_data.site_id:
            continue
        
        existing = db.query(Attendance).filter(
            Attendance.worker_id == worker_id,
            Attendance.attendance_date == bulk_data.attendance_date
        ).first()
        
        if existing:
            continue
        
        db_attendance = Attendance(
            worker_id=worker_id,
            site_id=bulk_data.site_id,
            attendance_date=bulk_data.attendance_date,
            check_in_time=bulk_data.check_in_time,
            status=bulk_data.status,
            method=bulk_data.method,
            ethiopian_date_year=eth_date[0],
            ethiopian_date_month=eth_date[1],
            ethiopian_date_day=eth_date[2]
        )
        db.add(db_attendance)
        attendances.append(db_attendance)
    
    db.commit()
    for att in attendances:
        db.refresh(att)
    
    return attendances


@router.get("/", response_model=List[AttendanceResponse])
def list_attendance(
    skip: int = 0,
    limit: int = 100,
    site_id: int = None,
    worker_id: int = None,
    date_from: date = None,
    date_to: date = None,
    is_verified: bool = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Attendance)
    
    accessible_sites = get_user_accessible_sites(current_user, db)
    if accessible_sites is not None:
        query = query.filter(Attendance.site_id.in_(accessible_sites))
    
    if site_id:
        if accessible_sites is not None and site_id not in accessible_sites:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this site"
            )
        query = query.filter(Attendance.site_id == site_id)
    
    if worker_id:
        query = query.filter(Attendance.worker_id == worker_id)
    if date_from:
        query = query.filter(Attendance.attendance_date >= date_from)
    if date_to:
        query = query.filter(Attendance.attendance_date <= date_to)
    if is_verified is not None:
        query = query.filter(Attendance.is_verified == is_verified)
    
    attendances = query.order_by(Attendance.attendance_date.desc()).offset(skip).limit(limit).all()
    return attendances


@router.get("/{attendance_id}", response_model=AttendanceResponse)
def get_attendance(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    attendance = db.query(Attendance).filter(Attendance.id == attendance_id).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance not found")
    return attendance


@router.patch("/{attendance_id}", response_model=AttendanceResponse)
def update_attendance(
    attendance_id: int,
    attendance_update: AttendanceUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    attendance = db.query(Attendance).filter(Attendance.id == attendance_id).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance not found")
    
    if attendance.is_locked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot update locked attendance record"
        )
    
    update_data = attendance_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(attendance, field, value)
    
    db.commit()
    db.refresh(attendance)
    return attendance


@router.post("/verify", response_model=dict)
def verify_attendance(
    verify_data: AttendanceVerify,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    attendances = db.query(Attendance).filter(
        Attendance.id.in_(verify_data.attendance_ids)
    ).all()
    
    if not attendances:
        raise HTTPException(status_code=404, detail="No attendance records found")
    
    for attendance in attendances:
        attendance.is_verified = True
        attendance.verified_by_id = current_user.id
        attendance.verified_at = datetime.utcnow()
        attendance.is_locked = True
        if verify_data.override_reason:
            attendance.override_reason = verify_data.override_reason
    
    db.commit()
    
    return {"message": f"Successfully verified {len(attendances)} attendance records"}


@router.delete("/{attendance_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_attendance(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    attendance = db.query(Attendance).filter(Attendance.id == attendance_id).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance not found")
    
    if attendance.is_locked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete locked attendance record"
        )
    
    db.delete(attendance)
    db.commit()
    return None
