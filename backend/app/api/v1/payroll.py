from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from decimal import Decimal

from app.core.database import get_db
from app.api.deps import get_current_user, get_user_accessible_sites, verify_site_access
from app.models.user import User, UserRole
from app.models.payroll import Payroll, PayrollItem, PayrollStatus, PayrollPeriodType
from app.models.worker import Worker
from app.models.attendance import Attendance
from app.models.overtime import Overtime
from app.models.work_type import PaymentMode, WorkType
from app.schemas.payroll import PayrollCreate, PayrollCalculate, PayrollApprove, PayrollResponse, PayrollItemResponse
from app.services.payment_period_service import PaymentPeriodService
from app.services.payroll_calculator import PayrollCalculator

router = APIRouter()
payroll_calc = PayrollCalculator()


@router.post("/", response_model=PayrollResponse, status_code=status.HTTP_201_CREATED)
def create_payroll(
    payroll_data: PayrollCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can create payroll runs"
        )
    
    if not verify_site_access(current_user, payroll_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    payroll_code = f"PAY-{payroll_data.site_id}-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
    
    db_payroll = Payroll(
        payroll_code=payroll_code,
        site_id=payroll_data.site_id,
        period_type=payroll_data.period_type,
        period_start=payroll_data.period_start,
        period_end=payroll_data.period_end,
        ethiopian_month=payroll_data.ethiopian_month,
        ethiopian_year=payroll_data.ethiopian_year,
        work_type_id=payroll_data.work_type_id,
        work_place_id=payroll_data.work_place_id,
        calculated_by_id=current_user.id,
    )
    
    db.add(db_payroll)
    db.commit()
    db.refresh(db_payroll)
    return db_payroll


@router.post("/calculate", response_model=PayrollResponse)
def calculate_payroll(
    calc_data: PayrollCalculate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can calculate payroll"
        )
    
    payroll = db.query(Payroll).filter(Payroll.id == calc_data.payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    if payroll.status != PayrollStatus.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only calculate payroll in DRAFT status"
        )
    
    attendances_query = db.query(Attendance).filter(
        Attendance.site_id == payroll.site_id,
        Attendance.attendance_date >= payroll.period_start,
        Attendance.attendance_date <= payroll.period_end,
        Attendance.is_verified == True
    )
    
    overtime_query = db.query(Overtime).filter(
        Overtime.site_id == payroll.site_id,
        Overtime.overtime_date >= payroll.period_start,
        Overtime.overtime_date <= payroll.period_end,
        Overtime.is_verified == True
    )

    # Smart cycle filtering: if work_type_id not explicitly provided, align to period_type
    has_cycle_filter = (
        payroll.work_type_id is not None
        or payroll.work_place_id is not None
        or payroll.period_type in [PayrollPeriodType.BI_WEEKLY, PayrollPeriodType.MONTHLY, PayrollPeriodType.WEEKLY]
    )

    if has_cycle_filter:
        attendances_query = attendances_query.join(Worker, Attendance.worker_id == Worker.id)
        overtime_query = overtime_query.join(Worker, Overtime.worker_id == Worker.id)
        
        if payroll.work_type_id:
            attendances_query = attendances_query.filter(Worker.work_type_id == payroll.work_type_id)
            overtime_query = overtime_query.filter(Worker.work_type_id == payroll.work_type_id)
        elif payroll.period_type == PayrollPeriodType.BI_WEEKLY:
            # 14-day / bi-weekly cycle: daily, hourly, piece rate, or configured <= 14 days
            attendances_query = attendances_query.join(WorkType, Worker.work_type_id == WorkType.id).filter(
                or_(
                    WorkType.payment_mode.in_([PaymentMode.DAILY_RATE, PaymentMode.PIECE_RATE, PaymentMode.HOURLY_RATE]),
                    WorkType.payment_period_days <= 14
                )
            )
            overtime_query = overtime_query.join(WorkType, Worker.work_type_id == WorkType.id).filter(
                or_(
                    WorkType.payment_mode.in_([PaymentMode.DAILY_RATE, PaymentMode.PIECE_RATE, PaymentMode.HOURLY_RATE]),
                    WorkType.payment_period_days <= 14
                )
            )
        elif payroll.period_type == PayrollPeriodType.MONTHLY:
            # Monthly salaried staff (Engineers, Foremen, Office Staff, Management)
            attendances_query = attendances_query.join(WorkType, Worker.work_type_id == WorkType.id).filter(
                or_(
                    WorkType.payment_mode == PaymentMode.MONTHLY_SALARY,
                    WorkType.payment_period_days >= 28
                )
            )
            overtime_query = overtime_query.join(WorkType, Worker.work_type_id == WorkType.id).filter(
                or_(
                    WorkType.payment_mode == PaymentMode.MONTHLY_SALARY,
                    WorkType.payment_period_days >= 28
                )
            )
        elif payroll.period_type == PayrollPeriodType.WEEKLY:
            attendances_query = attendances_query.join(WorkType, Worker.work_type_id == WorkType.id).filter(
                WorkType.payment_period_days == 7
            )
            overtime_query = overtime_query.join(WorkType, Worker.work_type_id == WorkType.id).filter(
                WorkType.payment_period_days == 7
            )
            
        if payroll.work_place_id:
            attendances_query = attendances_query.filter(Worker.work_place_id == payroll.work_place_id)
            overtime_query = overtime_query.filter(Worker.work_place_id == payroll.work_place_id)

    attendances = attendances_query.all()
    overtime_records = overtime_query.all()
    
    worker_overtime_lookup: dict = {}
    for ot in overtime_records:
        worker_overtime_lookup[ot.worker_id] = (
            worker_overtime_lookup.get(ot.worker_id, 0.0) + ot.hours
        )
    
    workers_query = db.query(Worker).filter(
        Worker.site_id == payroll.site_id,
        Worker.status == 'active'
    )
    if payroll.work_type_id:
        workers_query = workers_query.filter(Worker.work_type_id == payroll.work_type_id)
    elif payroll.period_type == PayrollPeriodType.BI_WEEKLY:
        # 14-day / bi-weekly cycle: daily, hourly, piece rate, or configured <= 14 days
        workers_query = workers_query.join(Worker.work_type).filter(
            or_(
                WorkType.payment_mode.in_([PaymentMode.DAILY_RATE, PaymentMode.PIECE_RATE, PaymentMode.HOURLY_RATE]),
                WorkType.payment_period_days <= 14
            )
        )
    elif payroll.period_type == PayrollPeriodType.MONTHLY:
        # Monthly salaried staff (Engineers, Foremen, Office Staff, Management)
        workers_query = workers_query.join(Worker.work_type).filter(
            or_(
                WorkType.payment_mode == PaymentMode.MONTHLY_SALARY,
                WorkType.payment_period_days >= 28
            )
        )
    elif payroll.period_type == PayrollPeriodType.WEEKLY:
        workers_query = workers_query.join(Worker.work_type).filter(
            WorkType.payment_period_days == 7
        )
        
    if payroll.work_place_id:
        workers_query = workers_query.filter(Worker.work_place_id == payroll.work_place_id)
    active_workers = workers_query.all()
    
    worker_attendance_summary = {
        w.id: {
            "days_worked": 0,
            "regular_hours": 0,
            "overtime_hours": worker_overtime_lookup.get(w.id, 0.0)
        } for w in active_workers
    }
    
    for att in attendances:
        if att.worker_id not in worker_attendance_summary:
            worker_attendance_summary[att.worker_id] = {
                "days_worked": 0,
                "regular_hours": 0,
                "overtime_hours": worker_overtime_lookup.get(att.worker_id, 0.0)
            }
        
        if att.status in ['present', 'late', 'excused', 'leave']:
            worker_attendance_summary[att.worker_id]["days_worked"] += 1
            worker_attendance_summary[att.worker_id]["regular_hours"] += att.regular_hours
        elif att.status == 'half_day':
            worker_attendance_summary[att.worker_id]["days_worked"] += 0.5
            worker_attendance_summary[att.worker_id]["regular_hours"] += (att.regular_hours or 8) / 2
            
        if getattr(att, "is_overtime_verified", False) and att.overtime_hours:
            worker_attendance_summary[att.worker_id]["overtime_hours"] += float(att.overtime_hours)
    
    workers_by_work_type = {}
    for worker_id, summary in worker_attendance_summary.items():
        if summary["days_worked"] == 0 and summary["overtime_hours"] == 0:
            continue
            
        worker = db.query(Worker).filter(Worker.id == worker_id).first()
        if not worker or not worker.work_type:
            continue
        
        wt = worker.work_type
        work_type_key = (wt.id, wt.name)
        
        if work_type_key not in workers_by_work_type:
            workers_by_work_type[work_type_key] = []
        
        # If worker has an individual base salary override set by admin, use it;
        # otherwise use the work type's configured base rate
        effective_base_rate = (
            Decimal(str(worker.base_salary))
            if (worker.base_salary is not None and worker.base_salary > 0)
            else wt.base_rate
        )
        
        from datetime import timedelta as _td
        
        cycle_start, cycle_end, _, _ = PaymentPeriodService.calculate_worker_period(
            payroll.period_start,
            payroll.period_end,
            wt.payment_period_days,
            wt.payment_period_start_date,
            wt.payment_mode,
        )
        
        total_working_days = sum(
            1 for i in range((cycle_end - cycle_start).days + 1)
            if (cycle_start + _td(days=i)).weekday() < 6  # Mon-Sat
        )
        
        # Determine the best effective overtime rate per hour:
        # 1. Individual worker's custom overtime rate (if set)
        # 2. Work type's configured overtime rate (if set)
        # 3. Dynamic statutory rate (1.25x hourly wage as per Ethiopian Labor Proclamation No. 1156/2019)
        #    Ensures Monthly Staff (30 days) and daily workers always receive their verified overtime pay!
        effective_ot_rate = Decimal("0")
        if worker.overtime_rate_per_hour is not None and worker.overtime_rate_per_hour > 0:
            effective_ot_rate = Decimal(str(worker.overtime_rate_per_hour))
        elif wt.overtime_rate_per_hour is not None and wt.overtime_rate_per_hour > 0:
            effective_ot_rate = Decimal(str(wt.overtime_rate_per_hour))
        else:
            if wt.payment_mode == PaymentMode.MONTHLY_SALARY and effective_base_rate > 0:
                # 26 standard working days * 8 hours = 208 working hours in a month
                hourly = Decimal(str(effective_base_rate)) / Decimal("208")
                effective_ot_rate = (hourly * Decimal("1.25")).quantize(Decimal("0.01"))
            elif wt.payment_mode == PaymentMode.DAILY_RATE and effective_base_rate > 0:
                hourly = Decimal(str(effective_base_rate)) / Decimal("8")
                effective_ot_rate = (hourly * Decimal("1.25")).quantize(Decimal("0.01"))
            elif wt.payment_mode == PaymentMode.HOURLY_RATE and effective_base_rate > 0:
                effective_ot_rate = (Decimal(str(effective_base_rate)) * Decimal("1.25")).quantize(Decimal("0.01"))

        workers_by_work_type[work_type_key].append({
            "worker_id": worker_id,
            "base_rate": effective_base_rate,
            "payment_mode": wt.payment_mode,
            "tax_rule": wt.tax_rule,
            "days_worked": summary["days_worked"],
            "regular_hours": summary["regular_hours"],
            "overtime_hours": summary["overtime_hours"],
            "overtime_rate_per_hour": effective_ot_rate,
            "pension_eligible": wt.pension_eligible,
            # IMPORTANT: Only use rates explicitly configured in the work type.
            # If not set, default to 0 so no deduction is ever made silently.
            "employee_pension_rate": wt.employee_pension_rate if wt.employee_pension_rate is not None else 0.0,
            "employer_pension_rate": wt.employer_pension_rate if wt.employer_pension_rate is not None else 0.0,
            "allocated_overtime_hours": worker.overtime_hours if worker.overtime_hours is not None else Decimal("0"),
            "allocated_overtime_rate": worker.overtime_rate_per_hour if worker.overtime_rate_per_hour is not None else Decimal("0"),
            "payroll_period_start": payroll.period_start,
            "payroll_period_end": payroll.period_end,
            "payment_period_days": wt.payment_period_days,
            "payment_period_start_date": wt.payment_period_start_date,
            "period_total_calendar_days": total_working_days,
        })
    
    sorted_work_types = sorted(workers_by_work_type.keys(), key=lambda x: x[1])
    
    worker_payroll_data = []
    for work_type_key in sorted_work_types:
        worker_payroll_data.extend(workers_by_work_type[work_type_key])
    
    payroll_items, totals = payroll_calc.calculate_bulk_payroll(worker_payroll_data)
    
    for item_data in payroll_items:
        db_item = PayrollItem(
            payroll_id=payroll.id,
            worker_id=item_data["worker_id"],
            payment_period_start=item_data.get("payment_period_start"),
            payment_period_end=item_data.get("payment_period_end"),
            payment_period_days=item_data.get("payment_period_days"),
            is_prorated=item_data.get("is_prorated", False),
            payment_period_type=item_data.get("payment_period_type"),
            days_worked=item_data["days_worked"],
            regular_hours=item_data["regular_hours"],
            overtime_hours=item_data["overtime_hours"],
            base_salary=item_data["base_salary"],
            overtime_pay=item_data["overtime_pay"],
            allocated_overtime_pay=item_data.get("allocated_overtime_pay", Decimal("0")),
            allowances=item_data["allowances"],
            gross_salary=item_data["gross_salary"],
            income_tax=item_data["income_tax"],
            employee_pension=item_data["employee_pension"],
            employer_pension=item_data["employer_pension"],
            cost_sharing=item_data["cost_sharing"],
            other_deductions=item_data["other_deductions"],
            total_deductions=item_data["total_deductions"],
            net_salary=item_data["net_salary"],
            tax_rule_applied=item_data.get("tax_rule_applied"),
        )
        db.add(db_item)
    
    payroll.total_gross_amount = totals["total_gross"]
    payroll.total_deductions = totals["total_deductions"]
    payroll.total_net_amount = totals["total_net"]
    payroll.total_employer_pension = totals["total_employer_pension"]
    payroll.status = PayrollStatus.CALCULATED
    
    db.commit()
    db.refresh(payroll)
    
    return payroll


@router.get("/", response_model=List[PayrollResponse])
def get_payrolls(
    site_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if site_id is not None:
        if not verify_site_access(current_user, site_id, db):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this site"
            )
        payrolls = db.query(Payroll).filter(
            Payroll.site_id == site_id
        ).order_by(Payroll.period_start.desc()).offset(skip).limit(limit).all()
    else:
        accessible_site_ids = get_user_accessible_sites(current_user, db)
        if accessible_site_ids is None:
            # Super admin / admin: return all payrolls
            payrolls = db.query(Payroll).order_by(
                Payroll.period_start.desc()
            ).offset(skip).limit(limit).all()
        elif accessible_site_ids:
            # Site-restricted user with assigned sites
            payrolls = db.query(Payroll).filter(
                Payroll.site_id.in_(accessible_site_ids)
            ).order_by(Payroll.period_start.desc()).offset(skip).limit(limit).all()
        else:
            # No site access at all
            payrolls = []

    return payrolls


@router.get("/{payroll_id}", response_model=PayrollResponse)
def get_payroll(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
        
    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
        
    return payroll


@router.get("/{payroll_id}/items", response_model=List[PayrollItemResponse])
def get_payroll_items(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
        
    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
        
    items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).order_by(Worker.full_name).all()
    
    return items


@router.delete("/{payroll_id}", status_code=status.HTTP_200_OK)
def delete_payroll(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Permanently delete a payroll run, its items, and any related payments.
    Accessible to super_admin, admin, or site_admin with site access.
    """
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll run not found")

    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete payroll for this site"
        )

    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can delete payroll runs"
        )

    # If already paid, only super admin can delete or reverse
    if payroll.status == PayrollStatus.PAID and current_user.role != UserRole.SUPER_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Completed/paid payrolls can only be deleted or reversed by a Super Administrator"
        )

    try:
        from app.models.payment import Payment

        # Clean up any payments linked to items of this payroll
        item_ids = [item.id for item in payroll.payroll_items]
        if item_ids:
            db.query(Payment).filter(Payment.payroll_item_id.in_(item_ids)).delete(synchronize_session=False)

        # Delete the payroll (payroll_items cascade automatically via relationship)
        db.delete(payroll)
        db.commit()

        return {"message": "Payroll deleted successfully", "id": payroll_id}
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete payroll: {str(e)}"
        )


@router.post("/approve", response_model=PayrollResponse)
def approve_payroll(
    approve_data: PayrollApprove,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Formally approve calculated payroll run. Transitions status to APPROVED.
    """
    payroll = db.query(Payroll).filter(Payroll.id == approve_data.payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
        
    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
        
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can formally approve payroll"
        )
        
    if payroll.status not in [PayrollStatus.DRAFT, PayrollStatus.CALCULATED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot approve payroll in {payroll.status} status. Must be CALCULATED."
        )
        
    payroll.status = PayrollStatus.APPROVED
    payroll.approved_by_id = current_user.id
    payroll.approved_at = date.today()
    if approve_data.notes:
        payroll.notes = (payroll.notes or "") + f" | Approved: {approve_data.notes}"
        
    db.commit()
    db.refresh(payroll)
    return payroll


@router.post("/{payroll_id}/lock")
def lock_payroll(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Lock payroll permanently. Transitions status to PAID/LOCKED and locks attendance records.
    """
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
        
    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
        
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can lock payroll"
        )
        
    payroll.status = PayrollStatus.PAID
    
    # Lock all attendance and overtime in this period so they cannot be altered or double-paid
    db.query(Attendance).filter(
        Attendance.site_id == payroll.site_id,
        Attendance.attendance_date >= payroll.period_start,
        Attendance.attendance_date <= payroll.period_end
    ).update({"is_locked": True, "is_overtime_locked": True}, synchronize_session=False)
    
    db.commit()
    db.refresh(payroll)
    return {
        "message": "Payroll locked and archived successfully. Associated attendances are sealed.",
        "payroll_id": payroll.id,
        "status": payroll.status
    }


@router.post("/{payroll_id}/items/{item_id}/mark-paid")
def mark_payroll_item_paid(
    payroll_id: int,
    item_id: int,
    is_paid: bool = Query(True),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Mark an individual worker's payroll item as paid or pending.
    """
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
        
    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
        
    item = db.query(PayrollItem).filter(
        PayrollItem.id == item_id,
        PayrollItem.payroll_id == payroll_id
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Payroll item not found")
        
    item.notes = (item.notes or "") + f" | Payment status: {'PAID' if is_paid else 'UNPAID'} by {current_user.username}"
    db.commit()
    return {
        "message": "Payment status updated",
        "payroll_id": payroll_id,
        "item_id": item.id,
        "is_paid": is_paid
    }


@router.get("/{payroll_id}/period-breakdown")
def get_payroll_period_breakdown(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Statistical and category breakdown of a payroll run.
    """
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
        
    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
        
    items = db.query(PayrollItem).filter(PayrollItem.payroll_id == payroll_id).all()
    
    by_work_type: Dict[str, Dict[str, Any]] = {}
    for item in items:
        wt_name = item.worker.work_type.name if (item.worker and item.worker.work_type) else "General"
        if wt_name not in by_work_type:
            by_work_type[wt_name] = {
                "name": wt_name,
                "worker_count": 0,
                "total_gross": 0.0,
                "total_net": 0.0,
                "total_tax": 0.0,
                "total_pension": 0.0
            }
        b = by_work_type[wt_name]
        b["worker_count"] += 1
        b["total_gross"] += float(item.gross_salary or 0)
        b["total_net"] += float(item.net_salary or 0)
        b["total_tax"] += float(item.income_tax or 0)
        b["total_pension"] += float(item.employee_pension or 0)
        
    return {
        "payroll_id": payroll.id,
        "payroll_code": payroll.payroll_code,
        "period_start": str(payroll.period_start),
        "period_end": str(payroll.period_end),
        "total_workers": len(items),
        "total_gross": float(payroll.total_gross_amount or 0),
        "total_net": float(payroll.total_net_amount or 0),
        "total_deductions": float(payroll.total_deductions or 0),
        "total_employer_pension": float(payroll.total_employer_pension or 0),
        "breakdown_by_work_type": list(by_work_type.values())
    }

