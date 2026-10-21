from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from loguru import logger

from app.core.database import get_db
from app.api.deps import (
    get_current_user, get_user_accessible_sites, verify_site_access
)
from app.core.ethiopian_calendar import EthiopianCalendar
from app.models.user import User, UserRole
from app.models.attendance import Attendance, AttendanceStatus, AttendanceMethod
from app.models.worker import Worker
from app.schemas.attendance import (
    AttendanceCreate,
    AttendanceBulkCreate,
    AttendanceMultiDayCreate,
    AttendanceUpdate,
    AttendanceVerify,
    AttendanceMultiDayVerify,
    AttendanceResponse,
    BulkOvertimeUpdate,
    OvertimeEntry
)

router = APIRouter()


def _attendance_to_dict(attendance: Attendance) -> Dict[str, Any]:
    """Convert Attendance model to dict with worker information"""
    return {
        "id": attendance.id,
        "worker_id": attendance.worker_id,
        "site_id": attendance.site_id,
        "attendance_date": attendance.attendance_date,
        "check_in_time": attendance.check_in_time,
        "check_out_time": attendance.check_out_time,
        "status": attendance.status,
        "method": attendance.method,
        "regular_hours": attendance.regular_hours,
        "overtime_hours": attendance.overtime_hours,
        "is_verified": attendance.is_verified,
        "verified_by_id": attendance.verified_by_id,
        "verified_at": attendance.verified_at,
        "is_overtime_verified": attendance.is_overtime_verified,
        "overtime_verified_by_id": attendance.overtime_verified_by_id,
        "overtime_verified_at": attendance.overtime_verified_at,
        "override_reason": attendance.override_reason,
        "notes": attendance.notes,
        "ethiopian_date_year": attendance.ethiopian_date_year,
        "ethiopian_date_month": attendance.ethiopian_date_month,
        "ethiopian_date_day": attendance.ethiopian_date_day,
        "is_locked": attendance.is_locked,
        "is_overtime_locked": attendance.is_overtime_locked,
        "created_at": attendance.created_at,
        "updated_at": attendance.updated_at,
        "worker_name": attendance.worker.full_name if attendance.worker else None,
        "employee_id": attendance.worker.employee_id if attendance.worker else None,
    }


@router.post(
    "/",
    response_model=AttendanceResponse,
    status_code=status.HTTP_201_CREATED
)
def create_attendance(
    attendance_data: AttendanceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    if not verify_site_access(current_user, attendance_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )

    worker = db.query(Worker).filter(
        Worker.id == attendance_data.worker_id
    ).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    if worker.site_id != attendance_data.site_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Worker does not belong to this site"
        )
    
    # Validate workplace access for admins (if restricted to specific workplaces)
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
            if worker.work_place_id not in accessible_workplace_ids:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have access to this worker's workplace"
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

    eth_date = EthiopianCalendar.gregorian_to_ethiopian(
        attendance_data.attendance_date
    )

    db_attendance = Attendance(
        **attendance_data.model_dump(),
        ethiopian_date_year=eth_date[0],
        ethiopian_date_month=eth_date[1],
        ethiopian_date_day=eth_date[2]
    )

    db.add(db_attendance)
    db.commit()
    db.refresh(db_attendance)
    return _attendance_to_dict(db_attendance)


@router.post(
    "/bulk",
    response_model=List[AttendanceResponse],
    status_code=status.HTTP_201_CREATED
)
def create_bulk_attendance(
    bulk_data: AttendanceBulkCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> List[Dict[str, Any]]:
    if not verify_site_access(current_user, bulk_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )

    eth_date = EthiopianCalendar.gregorian_to_ethiopian(
        bulk_data.attendance_date
    )
    
    # Get accessible workplaces for admins
    accessible_workplace_ids = None
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
        else:
            # Admin has NO workplace assignments - cannot create attendance
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No workplace assignment - Contact Super Admin"
            )

    attendances = []
    for worker_id in bulk_data.worker_ids:
        worker = db.query(Worker).filter(Worker.id == worker_id).first()
        if not worker or worker.site_id != bulk_data.site_id:
            continue
        
        # Check workplace access for admins
        if accessible_workplace_ids is not None:
            if worker.work_place_id not in accessible_workplace_ids:
                continue  # Skip workers not in accessible workplaces

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

    return [_attendance_to_dict(att) for att in attendances]


@router.post(
    "/multi-day",
    response_model=List[AttendanceResponse],
    status_code=status.HTTP_201_CREATED
)
def create_multi_day_attendance(
    multi_day_data: AttendanceMultiDayCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> List[Dict[str, Any]]:
    if not verify_site_access(current_user, multi_day_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )

    if not multi_day_data.attendance_dates:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No attendance dates provided"
        )

    today = date.today()
    future_dates = [d for d in multi_day_data.attendance_dates if d > today]
    if future_dates:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot mark attendance for future dates. Found {len(future_dates)} future date(s). Attendance can only be marked up to today."
        )

    worker = db.query(Worker).filter(Worker.id == multi_day_data.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    if worker.site_id != multi_day_data.site_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Worker does not belong to this site"
        )
    
    # Validate workplace access for admins (if restricted to specific workplaces)
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
            if worker.work_place_id not in accessible_workplace_ids:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have access to this worker's workplace"
                )

    created_attendances = []
    updated_attendances = []
    skipped_dates = []
    errors = []

    try:
        for attendance_date in multi_day_data.attendance_dates:
            try:
                existing = db.query(Attendance).filter(
                    Attendance.worker_id == multi_day_data.worker_id,
                    Attendance.attendance_date == attendance_date
                ).first()

                eth_date = EthiopianCalendar.gregorian_to_ethiopian(attendance_date)

                if existing:
                    if existing.is_verified:
                        skipped_dates.append(attendance_date)
                        continue
                    
                    existing.status = multi_day_data.status
                    existing.method = multi_day_data.method
                    if multi_day_data.check_in_time:
                        existing.check_in_time = multi_day_data.check_in_time
                    updated_attendances.append(existing)
                else:
                    db_attendance = Attendance(
                        worker_id=multi_day_data.worker_id,
                        site_id=multi_day_data.site_id,
                        attendance_date=attendance_date,
                        check_in_time=multi_day_data.check_in_time,
                        status=multi_day_data.status,
                        method=multi_day_data.method,
                        ethiopian_date_year=eth_date[0],
                        ethiopian_date_month=eth_date[1],
                        ethiopian_date_day=eth_date[2]
                    )
                    db.add(db_attendance)
                    created_attendances.append(db_attendance)
            except Exception as date_error:
                errors.append(f"Error processing date {attendance_date}: {str(date_error)}")
                continue

        if not created_attendances and not updated_attendances:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No attendance records were created or updated. All dates may be locked, verified, or invalid."
            )

        db.commit()
        
        all_attendances = created_attendances + updated_attendances
        for att in all_attendances:
            db.refresh(att)

        return [_attendance_to_dict(att) for att in all_attendances]
    
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create multi-day attendance: {str(e)}"
        )


@router.post(
    "/verify-multi-day",
    response_model=dict,
    status_code=status.HTTP_200_OK
)
def verify_multi_day_attendance(
    verify_data: AttendanceMultiDayVerify,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    # Verification authority: Site Engineer and above
    VERIFICATION_ROLES = [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]
    if current_user.role not in VERIFICATION_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Verification authority restricted to Site Engineer, Site Manager, or Administrator."
        )

    if not verify_site_access(current_user, verify_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )

    if not verify_data.attendance_dates:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No attendance dates provided"
        )

    today = date.today()
    future_dates = [d for d in verify_data.attendance_dates if d > today]
    if future_dates:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot verify attendance for future dates. Found {len(future_dates)} future date(s)."
        )

    worker = db.query(Worker).filter(Worker.id == verify_data.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    if worker.site_id != verify_data.site_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Worker does not belong to this site"
        )
    
    # Validate workplace access for admins
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
            if worker.work_place_id not in accessible_workplace_ids:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have access to this worker's workplace"
                )
        else:
            # Admin has NO workplace assignments - cannot verify attendance
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No workplace assignment - Contact Super Admin"
            )

    verified_count = 0
    skipped_count = 0
    not_found_dates = []

    try:
        for attendance_date in verify_data.attendance_dates:
            existing = db.query(Attendance).filter(
                Attendance.worker_id == verify_data.worker_id,
                Attendance.attendance_date == attendance_date
            ).first()

            if not existing:
                not_found_dates.append(attendance_date)
                continue

            if existing.is_verified:
                skipped_count += 1
                continue

            existing.is_verified = True
            existing.verified_by_id = current_user.id
            existing.verified_at = datetime.utcnow()
            if verify_data.override_reason:
                existing.override_reason = verify_data.override_reason
            
            verified_count += 1

        if verified_count == 0 and skipped_count == 0 and not_found_dates:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"No attendance records found for the specified dates. Please mark attendance first."
            )

        db.commit()

        message = f"Successfully verified {verified_count} attendance record(s)"
        if skipped_count > 0:
            message += f". {skipped_count} already verified"
        if not_found_dates:
            message += f". {len(not_found_dates)} date(s) had no attendance records"

        return {
            "message": message,
            "verified_count": verified_count,
            "skipped_count": skipped_count,
            "not_found_count": len(not_found_dates)
        }
    
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to verify multi-day attendance: {str(e)}"
        )


@router.get("/", response_model=List[AttendanceResponse])
def list_attendance(
    skip: int = 0,
    limit: int = 100,
    site_id: Optional[int] = None,
    worker_id: Optional[int] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    is_verified: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> List[Dict[str, Any]]:
    query = db.query(Attendance).join(Worker)

    accessible_sites = get_user_accessible_sites(current_user, db)
    if accessible_sites is not None:
        query = query.filter(Attendance.site_id.in_(accessible_sites))
    
    # Strict workplace filtering for admins
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            # Admin has workplace assignments - show only those workplaces
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
            query = query.filter(Worker.work_place_id.in_(accessible_workplace_ids))
        else:
            # Admin has NO workplace assignments - show nothing
            query = query.filter(Worker.id == -1)  # Impossible condition, returns empty

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

    attendances = query.order_by(
        Attendance.attendance_date.desc()
    ).offset(skip).limit(limit).all()
    
    return [_attendance_to_dict(att) for att in attendances]


@router.get("/{attendance_id}", response_model=AttendanceResponse)
def get_attendance(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    attendance = db.query(Attendance).join(Worker).filter(
        Attendance.id == attendance_id
    ).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance not found")
    
    # Verify the user has access to the site this attendance belongs to
    if not verify_site_access(current_user, attendance.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    return _attendance_to_dict(attendance)


@router.patch("/{attendance_id}", response_model=AttendanceResponse)
def update_attendance(
    attendance_id: int,
    attendance_update: AttendanceUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    attendance = db.query(Attendance).join(Worker).filter(
        Attendance.id == attendance_id
    ).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance not found")

    if attendance.is_locked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Attendance record is sealed for payroll and cannot be modified"
        )

    if attendance.is_verified and current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This attendance record has been verified by a Site Engineer. Only Site Engineers and Administrators can modify verified records."
        )

    update_data = attendance_update.model_dump(exclude_unset=True)

    if 'status' in update_data:
        from app.models.attendance import AttendanceStatus
        if update_data['status'] == AttendanceStatus.EXCUSED:
            override_reason = update_data.get('override_reason')
            if not override_reason and not attendance.override_reason:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(
                        "override_reason is mandatory when "
                        "marking attendance as EXCUSED"
                    )
                )

    for field, value in update_data.items():
        setattr(attendance, field, value)

    db.commit()
    db.refresh(attendance)
    return _attendance_to_dict(attendance)


@router.post("/verify", response_model=dict)
def verify_attendance(
    verify_data: AttendanceVerify,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    # Verification authority: Site Engineer and above
    VERIFICATION_ROLES = [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]
    if current_user.role not in VERIFICATION_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Verification authority restricted to Site Engineer, Site Manager, or Administrator."
        )

    attendances = db.query(Attendance).filter(
        Attendance.id.in_(verify_data.attendance_ids)
    ).all()

    if not attendances:
        raise HTTPException(
            status_code=404,
            detail="No attendance records found"
        )

    verified_count = 0
    locked_skipped = 0
    unauthorized_skipped = 0

    for attendance in attendances:
        if not verify_site_access(current_user, attendance.site_id, db):
            unauthorized_skipped += 1
            continue
        if attendance.is_locked:
            locked_skipped += 1
            continue

        attendance.is_verified = True
        attendance.verified_by_id = current_user.id
        attendance.verified_at = datetime.utcnow()
        if verify_data.override_reason:
            attendance.override_reason = verify_data.override_reason
        verified_count += 1

    db.commit()

    message = f"Successfully verified {verified_count} attendance record(s)"
    if locked_skipped > 0:
        message += f" ({locked_skipped} locked records skipped)"
    return {"message": message, "verified_count": verified_count}


@router.post("/unverify", response_model=dict)
def unverify_attendance(
    verify_data: AttendanceVerify,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    # Unverify authority: Site Engineer and above
    VERIFICATION_ROLES = [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]
    if current_user.role not in VERIFICATION_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Unverify authority restricted to Site Engineer, Site Manager, or Administrator."
        )

    attendances = db.query(Attendance).filter(
        Attendance.id.in_(verify_data.attendance_ids)
    ).all()

    if not attendances:
        raise HTTPException(
            status_code=404,
            detail="No attendance records found"
        )

    unverified_count = 0
    for attendance in attendances:
        if not verify_site_access(current_user, attendance.site_id, db):
            continue
        if attendance.is_locked:
            continue  # Cannot unverify locked records

        attendance.is_verified = False
        attendance.verified_by_id = None
        attendance.verified_at = None
        unverified_count += 1

    db.commit()

    message = f"Successfully unverified {unverified_count} attendance record(s)"
    return {"message": message, "unverified_count": unverified_count}


@router.get("/statistics", response_model=dict)
def get_attendance_statistics(
    site_id: int,
    date_from: date,
    date_to: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """Get attendance statistics for dashboard."""
    if not verify_site_access(current_user, site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )

    if date_to is None:
        date_to = date_from

    from app.models.attendance import AttendanceStatus

    query = db.query(Attendance).join(Worker).filter(
        Attendance.site_id == site_id,
        Attendance.attendance_date >= date_from,
        Attendance.attendance_date <= date_to
    )
    
    # Strict workplace filtering for admins
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            # Admin has workplace assignments - show only those workplaces
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
            query = query.filter(Worker.work_place_id.in_(accessible_workplace_ids))
        else:
            # Admin has NO workplace assignments - show nothing
            query = query.filter(Worker.id == -1)  # Impossible condition, returns empty

    total = query.count()
    present = query.filter(
        Attendance.status == AttendanceStatus.PRESENT
    ).count()
    absent = query.filter(
        Attendance.status == AttendanceStatus.ABSENT
    ).count()
    late = query.filter(
        Attendance.status == AttendanceStatus.LATE
    ).count()
    excused = query.filter(
        Attendance.status == AttendanceStatus.EXCUSED
    ).count()
    leave = query.filter(
        Attendance.status == AttendanceStatus.LEAVE
    ).count()
    half_day = query.filter(
        Attendance.status == AttendanceStatus.HALF_DAY
    ).count()
    verified = query.filter(Attendance.is_verified.is_(True)).count()
    locked = query.filter(Attendance.is_locked.is_(True)).count()

    # Query for regular hours with workplace filtering
    regular_hours_query = db.query(Attendance.regular_hours).join(Worker).filter(
        Attendance.site_id == site_id,
        Attendance.attendance_date >= date_from,
        Attendance.attendance_date <= date_to,
        Attendance.is_verified == True
    )
    
    # Query for overtime hours with workplace filtering
    overtime_hours_query = db.query(Attendance.overtime_hours).join(Worker).filter(
        Attendance.site_id == site_id,
        Attendance.attendance_date >= date_from,
        Attendance.attendance_date <= date_to,
        Attendance.is_overtime_verified == True
    )
    
    # Apply workplace filtering to hours queries
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
            regular_hours_query = regular_hours_query.filter(Worker.work_place_id.in_(accessible_workplace_ids))
            overtime_hours_query = overtime_hours_query.filter(Worker.work_place_id.in_(accessible_workplace_ids))
        else:
            regular_hours_query = regular_hours_query.filter(Worker.id == -1)
            overtime_hours_query = overtime_hours_query.filter(Worker.id == -1)
    
    total_regular_hours = regular_hours_query.all()
    total_overtime_hours = overtime_hours_query.all()

    return {
        "total": total,
        "present": present,
        "absent": absent,
        "late": late,
        "excused": excused,
        "leave": leave,
        "half_day": half_day,
        "verified": verified,
        "locked": locked,
        "total_regular_hours": sum([h[0] or 0 for h in total_regular_hours]),
        "total_overtime_hours": sum([h[0] or 0 for h in total_overtime_hours]),
        "date_range": {
            "from": str(date_from),
            "to": str(date_to)
        }
    }


@router.get("/payroll-impact", response_model=dict)
def get_payroll_impact(
    site_id: int,
    worker_id: Optional[int] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Calculate payroll impact based on attendance records.

    Shows how attendance translates to pay for workers.
    """
    if not verify_site_access(current_user, site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )

    if date_from is None:
        date_from = date.today().replace(day=1)
    if date_to is None:
        date_to = date.today()

    query = db.query(Attendance).join(Worker).filter(
        Attendance.site_id == site_id,
        Attendance.attendance_date >= date_from,
        Attendance.attendance_date <= date_to,
        Attendance.is_verified.is_(True)
    )
    
    # Strict workplace filtering for admins
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            # Admin has workplace assignments - show only those workplaces
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
            query = query.filter(Worker.work_place_id.in_(accessible_workplace_ids))
        else:
            # Admin has NO workplace assignments - show nothing
            query = query.filter(Worker.id == -1)  # Impossible condition, returns empty

    if worker_id:
        query = query.filter(Attendance.worker_id == worker_id)

    attendances = query.all()

    # Pre-fetch all workers in one query to avoid N+1
    unique_worker_ids = list(set(att.worker_id for att in attendances))
    workers_map: Dict[int, Worker] = {}
    if unique_worker_ids:
        workers_list = db.query(Worker).filter(Worker.id.in_(unique_worker_ids)).all()
        workers_map = {w.id: w for w in workers_list}

    worker_summary: Dict[int, Dict[str, Any]] = {}
    for att in attendances:
        if att.worker_id not in worker_summary:
            worker = workers_map.get(att.worker_id)
            worker_summary[att.worker_id] = {
                "worker_id": att.worker_id,
                "worker_name": worker.full_name if worker else "Unknown",
                "employee_id": worker.employee_id if worker else "N/A",
                "days_worked": 0,
                "days_present": 0,
                "days_absent": 0,
                "days_late": 0,
                "total_regular_hours": 0,
                "total_overtime_hours": 0,
                "attendance_records": []
            }

        summary = worker_summary[att.worker_id]
        summary["days_worked"] += 1
        summary["total_regular_hours"] += att.regular_hours or 0
        
        # Only include overtime hours if they are verified
        if att.is_overtime_verified:
            summary["total_overtime_hours"] += att.overtime_hours or 0

        if att.status == "present":
            summary["days_present"] += 1
        elif att.status == "absent":
            summary["days_absent"] += 1
        elif att.status == "late":
            summary["days_late"] += 1

        check_in_str = (
            att.check_in_time.strftime("%H:%M:%S")
            if att.check_in_time else None
        )
        check_out_str = (
            att.check_out_time.strftime("%H:%M:%S")
            if att.check_out_time else None
        )

        summary["attendance_records"].append({
            "date": str(att.attendance_date),
            "status": att.status,
            "regular_hours": att.regular_hours,
            "overtime_hours": att.overtime_hours,
            "check_in": check_in_str,
            "check_out": check_out_str,
        })

    return {
        "period": {
            "from": str(date_from),
            "to": str(date_to),
        },
        "site_id": site_id,
        "total_workers": len(worker_summary),
        "total_attendance_records": len(attendances),
        "worker_summaries": list(worker_summary.values())
    }


@router.delete("/{attendance_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_attendance(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> None:
    attendance = db.query(Attendance).filter(
        Attendance.id == attendance_id
    ).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance not found")

    # Locked records are permanently sealed — nobody can delete them
    if attendance.is_locked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Attendance record is sealed for payroll and cannot be deleted"
        )

    # Only SUPER_ADMIN and ADMIN can delete attendance records
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can delete attendance records"
        )

    # Verified records must be unverified first before deletion
    if attendance.is_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete verified attendance records. Unverify the record first, then delete."
        )
    
    if not verify_site_access(current_user, attendance.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    db.delete(attendance)
    db.commit()
    return None


@router.post("/overtime/bulk-update")
def bulk_update_overtime(
    bulk_data: BulkOvertimeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Bulk update overtime hours for multiple workers on a specific date.
    Requires existing attendance records - does not create new ones.
    """
    from loguru import logger
    
    logger.info(f"Overtime update: site={bulk_data.site_id}, date={bulk_data.attendance_date}, entries={len(bulk_data.overtime_entries)}, verify={bulk_data.verify}")
    
    if not verify_site_access(current_user, bulk_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    # Get accessible workplaces for admins
    accessible_workplace_ids = None
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
        else:
            # Admin has NO workplace assignments - cannot update overtime
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No workplace assignment - Contact Super Admin"
            )
    
    updated_count = 0
    errors = []
    
    for entry in bulk_data.overtime_entries:
        try:
            worker = db.query(Worker).filter(Worker.id == entry.worker_id).first()
            if not worker:
                errors.append(f"Worker ID {entry.worker_id} not found")
                continue
            
            if worker.site_id != bulk_data.site_id:
                errors.append(f"Worker ID {entry.worker_id} does not belong to site {bulk_data.site_id}")
                continue
            
            # Check workplace access for admins
            if accessible_workplace_ids is not None:
                if worker.work_place_id not in accessible_workplace_ids:
                    errors.append(f"Worker ID {entry.worker_id} is not in your assigned workplaces")
                    continue
            
            attendance = db.query(Attendance).filter(
                Attendance.worker_id == entry.worker_id,
                Attendance.attendance_date == bulk_data.attendance_date
            ).first()
            
            if attendance:
                if attendance.is_overtime_locked and not bulk_data.verify:
                    errors.append(f"Overtime for worker ID {entry.worker_id} is locked")
                    continue
                
                attendance.overtime_hours = entry.overtime_hours
                
                if bulk_data.verify:
                    attendance.is_overtime_verified = True
                    attendance.overtime_verified_by_id = current_user.id
                    attendance.overtime_verified_at = datetime.utcnow()
                    attendance.is_overtime_locked = True
                
                updated_count += 1
            else:
                # Create attendance record for overtime-only scenario
                eth_year, eth_month, eth_day = EthiopianCalendar.gregorian_to_ethiopian(bulk_data.attendance_date)
                attendance = Attendance(
                    worker_id=entry.worker_id,
                    site_id=bulk_data.site_id,
                    attendance_date=bulk_data.attendance_date,
                    status=AttendanceStatus.ABSENT,
                    method=AttendanceMethod.MANUAL_ENTRY,
                    regular_hours=0,
                    overtime_hours=entry.overtime_hours,
                    ethiopian_date_year=eth_year,
                    ethiopian_date_month=eth_month,
                    ethiopian_date_day=eth_day,
                )
                
                if bulk_data.verify:
                    attendance.is_overtime_verified = True
                    attendance.overtime_verified_by_id = current_user.id
                    attendance.overtime_verified_at = datetime.utcnow()
                    attendance.is_overtime_locked = True
                
                db.add(attendance)
                db.flush()
                updated_count += 1
        
        except Exception as e:
            errors.append(f"Error processing worker ID {entry.worker_id}: {str(e)}")
    
    db.commit()
    logger.info(f"Overtime update committed: {updated_count} updated, {len(errors)} errors")
    
    action = "verified and locked" if bulk_data.verify else "updated"
    result = {
        "message": f"Bulk overtime {action} completed",
        "updated": updated_count,
        "errors": errors,
        "total_processed": updated_count,
        "verified": bulk_data.verify
    }
    return result


class AttendanceLockRequest(BaseModel):
    attendance_ids: List[int]


@router.post("/lock")
def lock_attendances(
    lock_data: AttendanceLockRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Lock specific attendance records to prevent tampering or editing after verification.
    """
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]:
        raise HTTPException(status_code=403, detail="Only administrators can lock attendance records")
        
    records = db.query(Attendance).filter(Attendance.id.in_(lock_data.attendance_ids)).all()
    count = 0
    for r in records:
        if verify_site_access(current_user, r.site_id, db):
            r.is_locked = True
            r.is_overtime_locked = True
            count += 1
            
    db.commit()
    return {
        "message": f"Successfully locked {count} attendance records",
        "locked_count": count
    }


@router.post("/unlock")
def unlock_attendances(
    unlock_data: AttendanceLockRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Unlock sealed attendance records (Admin only).
    """
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN]:
        raise HTTPException(
            status_code=403,
            detail="Only Super Admins or Admins can unlock sealed attendance records"
        )
        
    records = db.query(Attendance).filter(Attendance.id.in_(unlock_data.attendance_ids)).all()
    count = 0
    for r in records:
        if verify_site_access(current_user, r.site_id, db):
            r.is_locked = False
            r.is_overtime_locked = False
            count += 1
            
    db.commit()
    return {
        "message": f"Successfully unlocked {count} attendance records",
        "unlocked_count": count
    }

