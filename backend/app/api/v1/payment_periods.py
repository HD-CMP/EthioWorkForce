from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import date, timedelta

from app.core.database import get_db
from app.api.deps import get_current_user, verify_site_access
from app.models.user import User
from app.models.payment_period import PaymentPeriod, PeriodStatus
from app.models.worker import Worker
from app.schemas.payment_period import PaymentPeriodCreate, PaymentPeriodUpdate, PaymentPeriodResponse
from app.core.ethiopian_calendar import EthiopianCalendar

router = APIRouter()


@router.post("/", response_model=PaymentPeriodResponse, status_code=status.HTTP_201_CREATED)
def create_payment_period(
    period_data: PaymentPeriodCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new payment period for a site"""
    if not verify_site_access(current_user, period_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    # Check for overlapping periods
    overlapping = db.query(PaymentPeriod).filter(
        PaymentPeriod.site_id == period_data.site_id,
        PaymentPeriod.status == PeriodStatus.ACTIVE,
        PaymentPeriod.period_start <= period_data.period_end,
        PaymentPeriod.period_end >= period_data.period_start
    ).first()
    
    if overlapping:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment period overlaps with an existing active period"
        )
    
    # Set is_current flag if this is the only active period or if it contains today
    today = date.today()
    is_current = period_data.period_start <= today <= period_data.period_end
    
    if is_current:
        # Unset current flag on other periods
        db.query(PaymentPeriod).filter(
            PaymentPeriod.site_id == period_data.site_id,
            PaymentPeriod.is_current == True
        ).update({"is_current": False})
    
    db_period = PaymentPeriod(**period_data.model_dump(), is_current=is_current)
    db.add(db_period)
    db.commit()
    db.refresh(db_period)
    
    return db_period


@router.get("/current/{site_id}", response_model=Optional[PaymentPeriodResponse])
def get_current_payment_period(
    site_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get the current active payment period for a site"""
    if not verify_site_access(current_user, site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    today = date.today()
    
    # First try to find period marked as current
    period = db.query(PaymentPeriod).filter(
        PaymentPeriod.site_id == site_id,
        PaymentPeriod.is_current == True,
        PaymentPeriod.status == PeriodStatus.ACTIVE
    ).first()
    
    # If not found, find period containing today
    if not period:
        period = db.query(PaymentPeriod).filter(
            PaymentPeriod.site_id == site_id,
            PaymentPeriod.status == PeriodStatus.ACTIVE,
            PaymentPeriod.period_start <= today,
            PaymentPeriod.period_end >= today
        ).first()
        
        # If found, mark it as current
        if period:
            period.is_current = True
            db.commit()
            db.refresh(period)
    
    return period


@router.get("/worker/{worker_id}", response_model=Optional[PaymentPeriodResponse])
def get_worker_payment_period(
    worker_id: int,
    reference_date: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get payment period for a worker based on their work type's payment period settings.
    Uses the work type's payment_period_start_date as the anchor for calculating payment periods.
    This ensures all workers of the same work type have synchronized payment periods.
    """
    worker = db.query(Worker).options(joinedload(Worker.work_type)).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    if not verify_site_access(current_user, worker.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this worker's site"
        )
    
    ref_date = reference_date or date.today()
    
    # Get payment period settings from work type or worker
    period_days = worker.work_type.payment_period_days if worker.work_type.payment_period_days else (worker.payment_period_days or 14)
    cycle_anchor = worker.work_type.payment_period_start_date if worker.work_type.payment_period_start_date else None
    
    # If work type has a payment_period_start_date set, use it as the anchor
    if not cycle_anchor:
        # Fallback: Look for the earliest period at this site to use as cycle anchor
        earliest_period = db.query(PaymentPeriod).filter(
            PaymentPeriod.site_id == worker.site_id
        ).order_by(PaymentPeriod.period_start.asc()).first()
        
        if earliest_period:
            cycle_anchor = earliest_period.period_start
        else:
            # No periods exist and no start date set - default to today
            cycle_anchor = ref_date
    
    # Calculate the payment period that contains the reference date
    days_since_anchor = (ref_date - cycle_anchor).days
    
    if days_since_anchor >= 0:
        # Reference date is on or after the anchor
        periods_elapsed = days_since_anchor // period_days
        period_start = cycle_anchor + timedelta(days=periods_elapsed * period_days)
    else:
        # Reference date is before the anchor - calculate backwards
        periods_before = (abs(days_since_anchor) + period_days - 1) // period_days
        period_start = cycle_anchor - timedelta(days=periods_before * period_days)
    
    period_end = period_start + timedelta(days=period_days - 1)
    
    # Check if this exact period already exists
    existing_period = db.query(PaymentPeriod).filter(
        PaymentPeriod.site_id == worker.site_id,
        PaymentPeriod.period_start == period_start,
        PaymentPeriod.period_end == period_end
    ).first()
    
    if existing_period:
        return existing_period
    
    # Convert to Ethiopian calendar
    eth_start = EthiopianCalendar.gregorian_to_ethiopian(period_start)
    eth_end = EthiopianCalendar.gregorian_to_ethiopian(period_end)
    
    # Auto-create the period
    new_period = PaymentPeriod(
        site_id=worker.site_id,
        period_start=period_start,
        period_end=period_end,
        period_days=period_days,
        status=PeriodStatus.ACTIVE,
        is_current=(period_start <= date.today() <= period_end),
        ethiopian_start_year=eth_start[0],
        ethiopian_start_month=eth_start[1],
        ethiopian_start_day=eth_start[2],
        ethiopian_end_year=eth_end[0],
        ethiopian_end_month=eth_end[1],
        ethiopian_end_day=eth_end[2]
    )
    
    db.add(new_period)
    db.commit()
    db.refresh(new_period)
    
    return new_period


@router.get("/site/{site_id}", response_model=List[PaymentPeriodResponse])
def list_site_payment_periods(
    site_id: int,
    status: Optional[PeriodStatus] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List all payment periods for a site"""
    if not verify_site_access(current_user, site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    query = db.query(PaymentPeriod).filter(PaymentPeriod.site_id == site_id)
    
    if status:
        query = query.filter(PaymentPeriod.status == status)
    
    periods = query.order_by(PaymentPeriod.period_start.desc()).offset(skip).limit(limit).all()
    return periods


@router.patch("/{period_id}", response_model=PaymentPeriodResponse)
def update_payment_period(
    period_id: int,
    update_data: PaymentPeriodUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a payment period (status, is_current flag)"""
    period = db.query(PaymentPeriod).filter(PaymentPeriod.id == period_id).first()
    if not period:
        raise HTTPException(status_code=404, detail="Payment period not found")
    
    if not verify_site_access(current_user, period.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    for key, value in update_data.model_dump(exclude_unset=True).items():
        setattr(period, key, value)
    
    if update_data.is_current:
        # Unset current flag on other periods
        db.query(PaymentPeriod).filter(
            PaymentPeriod.site_id == period.site_id,
            PaymentPeriod.id != period_id,
            PaymentPeriod.is_current == True
        ).update({"is_current": False})
    
    db.commit()
    db.refresh(period)
    
    return period


@router.post("/{period_id}/close", response_model=PaymentPeriodResponse)
def close_payment_period(
    period_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Close a payment period (prevents further modifications)"""
    period = db.query(PaymentPeriod).filter(PaymentPeriod.id == period_id).first()
    if not period:
        raise HTTPException(status_code=404, detail="Payment period not found")
    
    if not verify_site_access(current_user, period.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    if period.status == PeriodStatus.LOCKED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot close a locked period"
        )
    
    period.status = PeriodStatus.CLOSED
    period.is_current = False
    
    db.commit()
    db.refresh(period)
    
    return period
