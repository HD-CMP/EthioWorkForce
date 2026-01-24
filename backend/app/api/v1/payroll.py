from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from decimal import Decimal

from app.core.database import get_db
from app.api.deps import get_current_user, get_user_accessible_sites, verify_site_access
from app.models.user import User
from app.models.payroll import Payroll, PayrollItem, PayrollStatus
from app.models.worker import Worker
from app.models.attendance import Attendance
from app.schemas.payroll import PayrollCreate, PayrollCalculate, PayrollApprove, PayrollResponse
from app.services.payroll_calculator import PayrollCalculator

router = APIRouter()
payroll_calc = PayrollCalculator()


@router.post("/", response_model=PayrollResponse, status_code=status.HTTP_201_CREATED)
def create_payroll(
    payroll_data: PayrollCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
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
    payroll = db.query(Payroll).filter(Payroll.id == calc_data.payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    if payroll.status != PayrollStatus.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only calculate payroll in DRAFT status"
        )
    
    attendances = db.query(Attendance).filter(
        Attendance.site_id == payroll.site_id,
        Attendance.attendance_date >= payroll.period_start,
        Attendance.attendance_date <= payroll.period_end,
        Attendance.is_verified == True
    ).all()
    
    worker_attendance_summary = {}
    for att in attendances:
        if att.worker_id not in worker_attendance_summary:
            worker_attendance_summary[att.worker_id] = {
                "days_worked": 0,
                "regular_hours": 0,
                "overtime_hours": 0
            }
        worker_attendance_summary[att.worker_id]["days_worked"] += 1
        worker_attendance_summary[att.worker_id]["regular_hours"] += att.regular_hours
        worker_attendance_summary[att.worker_id]["overtime_hours"] += att.overtime_hours
    
    worker_payroll_data = []
    for worker_id, summary in worker_attendance_summary.items():
        worker = db.query(Worker).filter(Worker.id == worker_id).first()
        if not worker or not worker.work_type:
            continue
        
        wt = worker.work_type
        worker_payroll_data.append({
            "worker_id": worker_id,
            "base_rate": wt.base_rate,
            "payment_mode": wt.payment_mode,
            "tax_rule": wt.tax_rule,
            "days_worked": summary["days_worked"],
            "regular_hours": summary["regular_hours"],
            "overtime_hours": summary["overtime_hours"],
            "overtime_multiplier": wt.overtime_multiplier or 1.5,
            "pension_eligible": wt.pension_eligible,
            "employee_pension_rate": wt.employee_pension_rate or 0.07,
            "employer_pension_rate": wt.employer_pension_rate or 0.11,
        })
    
    payroll_items, totals = payroll_calc.calculate_bulk_payroll(worker_payroll_data)
    
    for item_data in payroll_items:
        db_item = PayrollItem(
            payroll_id=payroll.id,
            worker_id=item_data["worker_id"],
            days_worked=item_data["days_worked"],
            regular_hours=item_data["regular_hours"],
            overtime_hours=item_data["overtime_hours"],
            base_salary=item_data["base_salary"],
            overtime_pay=item_data["overtime_pay"],
            allowances=item_data["allowances"],
            gross_salary=item_data["gross_salary"],
            income_tax=item_data["income_tax"],
            employee_pension=item_data["employee_pension"],
            employer_pension=item_data["employer_pension"],
            cost_sharing=item_data["cost_sharing"],
            other_deductions=item_data["other_deductions"],
            total_deductions=item_data["total_deductions"],
            net_salary=item_data["net_salary"],
            tax_rule_applied=item_data["tax_rule_applied"],
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


@router.post("/approve", response_model=PayrollResponse)
def approve_payroll(
    approve_data: PayrollApprove,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    payroll = db.query(Payroll).filter(Payroll.id == approve_data.payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    if payroll.status != PayrollStatus.CALCULATED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only approve payroll in CALCULATED status"
        )
    
    payroll.status = PayrollStatus.APPROVED
    payroll.approved_by_id = current_user.id
    payroll.approved_at = datetime.utcnow().date()
    if approve_data.notes:
        payroll.notes = approve_data.notes
    
    db.commit()
    db.refresh(payroll)
    return payroll


@router.get("/", response_model=List[PayrollResponse])
def list_payrolls(
    skip: int = 0,
    limit: int = 100,
    site_id: int = None,
    status: PayrollStatus = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Payroll)
    
    accessible_sites = get_user_accessible_sites(current_user, db)
    if accessible_sites is not None:
        query = query.filter(Payroll.site_id.in_(accessible_sites))
    
    if site_id:
        if accessible_sites is not None and site_id not in accessible_sites:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this site"
            )
        query = query.filter(Payroll.site_id == site_id)
    
    if status:
        query = query.filter(Payroll.status == status)
    
    payrolls = query.order_by(Payroll.created_at.desc()).offset(skip).limit(limit).all()
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
    return payroll


@router.delete("/{payroll_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_payroll(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    if payroll.status in [PayrollStatus.APPROVED, PayrollStatus.PAID]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete approved or paid payroll"
        )
    
    db.delete(payroll)
    db.commit()
    return None
