from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from decimal import Decimal
import io

from app.core.database import get_db
from app.api.deps import get_current_user, verify_site_access, get_user_accessible_sites
from app.models.user import User, UserRole
from app.models.payroll import Payroll, PayrollItem, PayrollStatus
from app.models.worker import Worker, WorkerStatus
from app.models.site import Site
from app.models.work_type import WorkType
from app.models.work_place import WorkPlace
from app.models.attendance import Attendance
from app.models.overtime import Overtime
from app.models.payment import PaymentMethod
from app.services.payment_export import PaymentExportService
from app.services.pension_report import PensionReportService

router = APIRouter()
payment_export = PaymentExportService()
pension_report = PensionReportService()


@router.get("/payroll/{payroll_id}/export/cbe")
def export_payroll_cbe_format(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Export payroll in CBE (Commercial Bank of Ethiopia) Excel format"""
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).all()
    
    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "bank_account_number": item.worker.bank_account_number or "",
            "net_salary": item.net_salary,
            "payroll_code": payroll.payroll_code
        })
    
    excel_bytes = payment_export.export_cbe_bank_format(export_data)
    
    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=CBE_Payroll_{payroll.payroll_code}.xlsx"
        }
    )


@router.get("/payroll/{payroll_id}/export/dashen")
def export_payroll_dashen_format(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Export payroll in Dashen Bank Excel format"""
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).all()
    
    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "bank_account_number": item.worker.bank_account_number or "",
            "net_salary": item.net_salary,
            "payroll_code": payroll.payroll_code
        })
    
    excel_bytes = payment_export.export_dashen_bank_format(export_data)
    
    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=Dashen_Payroll_{payroll.payroll_code}.xlsx"
        }
    )


@router.get("/payroll/{payroll_id}/export/awash")
def export_payroll_awash_format(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Export payroll in Awash Bank Excel format"""
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).all()
    
    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "bank_account_number": item.worker.bank_account_number or "",
            "net_salary": item.net_salary,
            "payroll_code": payroll.payroll_code
        })
    
    excel_bytes = payment_export.export_awash_bank_format(export_data)
    
    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=Awash_Payroll_{payroll.payroll_code}.xlsx"
        }
    )


@router.get("/payroll/{payroll_id}/export/telebirr")
def export_payroll_telebirr_format(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Export payroll in Telebirr CSV format for bulk payment"""
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).all()
    
    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "phone_number": item.worker.phone_number or "",
            "net_salary": item.net_salary
        })
    
    csv_content = payment_export.export_telebirr_csv(export_data)
    
    return StreamingResponse(
        io.StringIO(csv_content),
        media_type="text/csv",
        headers={
            "Content-Disposition": f"attachment; filename=Telebirr_Payroll_{payroll.payroll_code}.csv"
        }
    )


@router.get("/payroll/{payroll_id}/export/mpesa")
def export_payroll_mpesa_format(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Export payroll in M-Pesa CSV format for bulk payment"""
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).all()
    
    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "phone_number": item.worker.phone_number or "",
            "net_salary": item.net_salary
        })
    
    csv_content = payment_export.export_mpesa_csv(export_data)
    
    return StreamingResponse(
        io.StringIO(csv_content),
        media_type="text/csv",
        headers={
            "Content-Disposition": f"attachment; filename=MPesa_Payroll_{payroll.payroll_code}.csv"
        }
    )


@router.get("/payroll/{payroll_id}/export/cash-sheet")
def export_cash_payment_sheet(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Export Cash Payment Sheet with signature lines"""
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).all()
    
    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "net_salary": item.net_salary
        })
    
    period_str = f"{payroll.period_start} to {payroll.period_end}"
    if payroll.ethiopian_month and payroll.ethiopian_year:
        period_str = f"{payroll.ethiopian_month} {payroll.ethiopian_year}"
    
    excel_bytes = payment_export.export_cash_payment_sheet(
        export_data,
        payroll.payroll_code,
        period_str
    )
    
    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=Cash_Payment_Sheet_{payroll.payroll_code}.xlsx"
        }
    )


@router.get("/payroll/{payroll_id}/pension-declaration/excel")
def export_pension_declaration_excel(
    payroll_id: int,
    organization_name: str = Query(..., description="Organization name for declaration"),
    tin_number: str = Query(..., description="Tax Identification Number"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Generate Ethiopian Pension Declaration Form in Excel format"""
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).all()
    
    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "gross_salary": item.gross_salary,
            "employee_pension": item.employee_pension,
            "employer_pension": item.employer_pension,
            "tax_rule_applied": item.tax_rule_applied
        })
    
    period_str = f"{payroll.period_start} to {payroll.period_end}"
    if payroll.ethiopian_month and payroll.ethiopian_year:
        period_str = f"{payroll.ethiopian_month} {payroll.ethiopian_year}"
    
    excel_bytes = pension_report.generate_pension_declaration_excel(
        organization_name=organization_name,
        tin_number=tin_number,
        period=period_str,
        payroll_items=export_data
    )
    
    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=Pension_Declaration_{payroll.payroll_code}.xlsx"
        }
    )


@router.get("/payroll/{payroll_id}/pension-declaration/pdf")
def export_pension_declaration_pdf(
    payroll_id: int,
    organization_name: str = Query(..., description="Organization name for declaration"),
    tin_number: str = Query(..., description="Tax Identification Number"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Generate Ethiopian Pension Declaration Form in PDF format"""
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
    
    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).all()
    
    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "gross_salary": item.gross_salary,
            "employee_pension": item.employee_pension,
            "employer_pension": item.employer_pension,
            "tax_rule_applied": item.tax_rule_applied
        })
    
    period_str = f"{payroll.period_start} to {payroll.period_end}"
    if payroll.ethiopian_month and payroll.ethiopian_year:
        period_str = f"{payroll.ethiopian_month} {payroll.ethiopian_year}"
    
    pdf_bytes = pension_report.generate_pension_declaration_pdf(
        organization_name=organization_name,
        tin_number=tin_number,
        period=period_str,
        payroll_items=export_data
    )
    
    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename=Pension_Declaration_{payroll.payroll_code}.pdf"
        }
    )


# ─── Enterprise Executive Reporting & Analytics Endpoints ────────────────────

@router.get("/dashboard")
def get_reports_dashboard(
    site_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Executive Analytics & KPI Summary for Enterprise Reports Hub
    """
    accessible_sites = get_user_accessible_sites(current_user, db)
    
    # 1. Workforce Queries
    worker_q = db.query(Worker)
    if site_id:
        if not verify_site_access(current_user, site_id, db):
            raise HTTPException(status_code=403, detail="Access denied to this site")
        worker_q = worker_q.filter(Worker.site_id == site_id)
    elif accessible_sites is not None:
        worker_q = worker_q.filter(Worker.site_id.in_(accessible_sites))

    total_workers = worker_q.count()
    active_workers = worker_q.filter(Worker.status == WorkerStatus.ACTIVE).count()
    inactive_workers = worker_q.filter(Worker.status == WorkerStatus.INACTIVE).count()
    terminated_workers = worker_q.filter(Worker.status == WorkerStatus.TERMINATED).count()
    suspended_workers = worker_q.filter(Worker.status == WorkerStatus.SUSPENDED).count()

    # Sites distribution
    sites_list = []
    sites_q = db.query(Site).filter(Site.is_active == True)
    if site_id:
        sites_q = sites_q.filter(Site.id == site_id)
    elif accessible_sites is not None:
        sites_q = sites_q.filter(Site.id.in_(accessible_sites))

    for s in sites_q.all():
        w_count = db.query(Worker).filter(Worker.site_id == s.id, Worker.status == WorkerStatus.ACTIVE).count()
        sites_list.append({
            "site_id": s.id,
            "site_name": s.name,
            "site_code": s.code,
            "worker_count": w_count
        })

    # Work types distribution
    work_types_list = []
    wt_q = db.query(
        WorkType.id,
        WorkType.name,
        WorkType.payment_mode,
        WorkType.base_rate,
        func.count(Worker.id).label("count")
    ).outerjoin(Worker, (Worker.work_type_id == WorkType.id) & (Worker.status == WorkerStatus.ACTIVE))
    
    if site_id:
        wt_q = wt_q.filter(Worker.site_id == site_id)
    elif accessible_sites is not None:
        wt_q = wt_q.filter((Worker.site_id.in_(accessible_sites)) | (Worker.id == None))

    wt_q = wt_q.group_by(WorkType.id, WorkType.name, WorkType.payment_mode, WorkType.base_rate)
    for wt in wt_q.all():
        work_types_list.append({
            "work_type_id": wt.id,
            "name": wt.name,
            "payment_mode": wt.payment_mode,
            "base_rate": float(wt.base_rate or 0),
            "worker_count": wt.count
        })

    # 2. Attendance & Overtime KPI (last 30 days)
    thirty_days_ago = date.today() - timedelta(days=30)
    att_q = db.query(Attendance).filter(Attendance.attendance_date >= thirty_days_ago)
    ot_q = db.query(Overtime).filter(Overtime.overtime_date >= thirty_days_ago)
    
    if site_id:
        att_q = att_q.filter(Attendance.site_id == site_id)
        ot_q = ot_q.filter(Overtime.site_id == site_id)
    elif accessible_sites is not None:
        att_q = att_q.filter(Attendance.site_id.in_(accessible_sites))
        ot_q = ot_q.filter(Overtime.site_id.in_(accessible_sites))

    att_records = att_q.all()
    present_cnt = sum(1 for a in att_records if a.status == 'present')
    late_cnt = sum(1 for a in att_records if a.status == 'late')
    half_day_cnt = sum(1 for a in att_records if a.status == 'half_day')
    excused_cnt = sum(1 for a in att_records if a.status == 'excused')
    leave_cnt = sum(1 for a in att_records if a.status == 'leave')
    absent_cnt = sum(1 for a in att_records if a.status == 'absent')
    total_att_records = len(att_records)

    presenteeism_rate = 0.0
    if total_att_records > 0:
        effective_days = present_cnt + late_cnt + (half_day_cnt * 0.5) + excused_cnt + leave_cnt
        presenteeism_rate = round((effective_days / total_att_records) * 100, 1)

    ot_records = ot_q.all()
    total_ot_hours = sum(o.hours for o in ot_records)
    verified_ot_hours = sum(o.hours for o in ot_records if o.is_verified)

    # 3. Payroll Totals
    payroll_q = db.query(Payroll)
    if site_id:
        payroll_q = payroll_q.filter(Payroll.site_id == site_id)
    elif accessible_sites is not None:
        payroll_q = payroll_q.filter(Payroll.site_id.in_(accessible_sites))

    payrolls = payroll_q.order_by(Payroll.period_start.desc()).all()
    total_gross_disbursed = sum(p.total_gross_amount for p in payrolls)
    total_net_disbursed = sum(p.total_net_amount for p in payrolls)
    total_deductions = sum(p.total_deductions for p in payrolls)
    total_employer_pension = sum(p.total_employer_pension for p in payrolls)

    recent_payrolls = []
    for p in payrolls[:5]:
        recent_payrolls.append({
            "id": p.id,
            "payroll_code": p.payroll_code,
            "period_start": str(p.period_start),
            "period_end": str(p.period_end),
            "status": p.status,
            "total_gross_amount": float(p.total_gross_amount),
            "total_net_amount": float(p.total_net_amount),
            "total_deductions": float(p.total_deductions),
            "total_employer_pension": float(p.total_employer_pension),
            "employee_count": len(p.payroll_items) if p.payroll_items else 0
        })

    return {
        "workforce": {
            "total_workers": total_workers,
            "active_workers": active_workers,
            "inactive_workers": inactive_workers,
            "terminated_workers": terminated_workers,
            "suspended_workers": suspended_workers,
            "retention_rate": round((active_workers / total_workers * 100), 1) if total_workers > 0 else 0
        },
        "sites_distribution": sites_list,
        "work_types_distribution": work_types_list,
        "attendance_analytics": {
            "period_days": 30,
            "total_records": total_att_records,
            "present_count": present_cnt,
            "late_count": late_cnt,
            "half_day_count": half_day_cnt,
            "excused_count": excused_cnt,
            "leave_count": leave_cnt,
            "absent_count": absent_cnt,
            "presenteeism_rate": presenteeism_rate
        },
        "overtime_analytics": {
            "total_hours": round(total_ot_hours, 2),
            "verified_hours": round(verified_ot_hours, 2),
            "total_entries": len(ot_records)
        },
        "payroll_analytics": {
            "total_payrolls": len(payrolls),
            "total_gross_disbursed": float(total_gross_disbursed),
            "total_net_disbursed": float(total_net_disbursed),
            "total_deductions": float(total_deductions),
            "total_employer_pension": float(total_employer_pension),
            "recent_payrolls": recent_payrolls
        }
    }


@router.get("/tax-compliance/{payroll_id}")
def get_tax_compliance_report(
    payroll_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    ERCA Income Tax Schedule & Statutory Compliance Report (JSON)
    """
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
        
    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(status_code=403, detail="Access denied to this site")

    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).order_by(Worker.full_name).all()

    items_data = []
    tot_gross = Decimal("0")
    tot_emp_pension = Decimal("0")
    tot_taxable = Decimal("0")
    tot_tax = Decimal("0")
    tot_empr_pension = Decimal("0")
    tot_remittance = Decimal("0")

    for item in payroll_items:
        gross = Decimal(str(item.gross_salary or 0))
        emp_pen = Decimal(str(item.employee_pension or 0))
        taxable = gross - emp_pen if gross >= emp_pen else Decimal("0")
        tax = Decimal(str(item.income_tax or 0))
        empr_pen = Decimal(str(item.employer_pension or 0))
        remit = tax + emp_pen + empr_pen

        tot_gross += gross
        tot_emp_pension += emp_pen
        tot_taxable += taxable
        tot_tax += tax
        tot_empr_pension += empr_pen
        tot_remittance += remit

        items_data.append({
            "worker_id": item.worker_id,
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "national_id": item.worker.national_id or "",
            "gross_salary": float(gross),
            "employee_pension": float(emp_pen),
            "taxable_income": float(taxable),
            "tax_rule_applied": item.tax_rule_applied or "standard",
            "income_tax": float(tax),
            "employer_pension": float(empr_pen),
            "total_remittance": float(remit)
        })

    period_str = f"{payroll.period_start} to {payroll.period_end}"
    if payroll.ethiopian_month and payroll.ethiopian_year:
        period_str = f"{payroll.ethiopian_month} {payroll.ethiopian_year}"

    return {
        "payroll_id": payroll.id,
        "payroll_code": payroll.payroll_code,
        "site_id": payroll.site_id,
        "site_name": payroll.site.name if payroll.site else "",
        "period": period_str,
        "period_start": str(payroll.period_start),
        "period_end": str(payroll.period_end),
        "employee_count": len(items_data),
        "summary": {
            "total_gross_salary": float(tot_gross),
            "total_employee_pension": float(tot_emp_pension),
            "total_taxable_income": float(tot_taxable),
            "total_income_tax": float(tot_tax),
            "total_employer_pension": float(tot_empr_pension),
            "total_statutory_remittance": float(tot_remittance)
        },
        "items": items_data
    }


@router.get("/tax-compliance/{payroll_id}/excel")
def export_tax_compliance_excel(
    payroll_id: int,
    organization_name: str = Query("EthioWorkforce Enterprise", description="Organization Name"),
    tin_number: str = Query("", description="TIN Number"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Download official ERCA Tax Schedule in Excel format
    """
    payroll = db.query(Payroll).filter(Payroll.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll not found")
        
    if not verify_site_access(current_user, payroll.site_id, db):
        raise HTTPException(status_code=403, detail="Access denied to this site")

    payroll_items = db.query(PayrollItem).filter(
        PayrollItem.payroll_id == payroll_id
    ).join(Worker).order_by(Worker.full_name).all()

    export_data = []
    for item in payroll_items:
        export_data.append({
            "employee_id": item.worker.employee_id,
            "worker_name": item.worker.full_name,
            "national_id": item.worker.national_id or "",
            "gross_salary": item.gross_salary,
            "employee_pension": item.employee_pension,
            "income_tax": item.income_tax,
            "employer_pension": item.employer_pension,
            "tax_rule_applied": item.tax_rule_applied
        })

    period_str = f"{payroll.period_start} to {payroll.period_end}"
    if payroll.ethiopian_month and payroll.ethiopian_year:
        period_str = f"{payroll.ethiopian_month} {payroll.ethiopian_year}"

    excel_bytes = payment_export.export_erca_tax_schedule_excel(
        payroll_code=payroll.payroll_code,
        period_str=period_str,
        payroll_items=export_data,
        org_name=organization_name,
        tin_number=tin_number
    )

    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=ERCA_Tax_Schedule_{payroll.payroll_code}.xlsx"
        }
    )


@router.get("/worker-census")
def get_worker_census_report(
    site_id: Optional[int] = None,
    work_type_id: Optional[int] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> List[Dict[str, Any]]:
    """
    Workforce Census & Demographic Registry (JSON)
    """
    accessible_sites = get_user_accessible_sites(current_user, db)
    q = db.query(Worker)

    if site_id:
        if not verify_site_access(current_user, site_id, db):
            raise HTTPException(status_code=403, detail="Access denied to this site")
        q = q.filter(Worker.site_id == site_id)
    elif accessible_sites is not None:
        q = q.filter(Worker.site_id.in_(accessible_sites))

    if work_type_id:
        q = q.filter(Worker.work_type_id == work_type_id)
    if status:
        q = q.filter(Worker.status == status)

    workers = q.order_by(Worker.full_name).all()
    results = []
    for w in workers:
        results.append({
            "id": w.id,
            "employee_id": w.employee_id,
            "full_name": w.full_name,
            "phone_number": w.phone_number or "",
            "national_id": w.national_id or "",
            "site_id": w.site_id,
            "site_name": w.site.name if w.site else "",
            "work_place_name": w.work_place.name if w.work_place else "",
            "work_type_id": w.work_type_id,
            "work_type_name": w.work_type.name if w.work_type else "",
            "hierarchy_level": w.work_type.hierarchy_level if w.work_type else None,
            "payment_mode": w.work_type.payment_mode if w.work_type else "",
            "base_rate": float(w.base_salary or (w.work_type.base_rate if w.work_type else 0) or 0),
            "bank_name": w.bank_name or "",
            "bank_account_number": w.bank_account_number or "",
            "status": w.status,
            "hire_date": str(w.hire_date) if w.hire_date else ""
        })

    return results


@router.get("/worker-census/excel")
def export_worker_census_excel_endpoint(
    site_id: Optional[int] = None,
    work_type_id: Optional[int] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Download Workforce Census & HR Register in Excel format
    """
    workers_data = get_worker_census_report(site_id, work_type_id, status, db, current_user)
    site_name = "All Sites"
    if site_id:
        site_obj = db.query(Site).filter(Site.id == site_id).first()
        if site_obj:
            site_name = site_obj.name

    excel_bytes = payment_export.export_worker_census_excel(workers_data, site_name=site_name)

    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=Workforce_Census_{datetime.utcnow().strftime('%Y%m%d')}.xlsx"
        }
    )


@router.get("/attendance-roster")
def get_attendance_roster_report(
    site_id: int,
    date_from: date = Query(..., description="Start date (YYYY-MM-DD)"),
    date_to: date = Query(..., description="End date (YYYY-MM-DD)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Attendance & Overtime Ledger Summary for a site and date range (JSON)
    """
    if not verify_site_access(current_user, site_id, db):
        raise HTTPException(status_code=403, detail="Access denied to this site")

    site_obj = db.query(Site).filter(Site.id == site_id).first()
    workers = db.query(Worker).filter(Worker.site_id == site_id, Worker.status == WorkerStatus.ACTIVE).all()

    att_records = db.query(Attendance).filter(
        Attendance.site_id == site_id,
        Attendance.attendance_date >= date_from,
        Attendance.attendance_date <= date_to
    ).all()

    ot_records = db.query(Overtime).filter(
        Overtime.site_id == site_id,
        Overtime.overtime_date >= date_from,
        Overtime.overtime_date <= date_to
    ).all()

    # Group by worker
    worker_map = {}
    for w in workers:
        ot_rate = Decimal(str(w.overtime_rate_per_hour or (w.work_type.overtime_rate_per_hour if w.work_type else 0) or 0))
        worker_map[w.id] = {
            "worker_id": w.id,
            "employee_id": w.employee_id,
            "worker_name": w.full_name,
            "site_name": site_obj.name if site_obj else "",
            "present_count": 0,
            "late_count": 0,
            "half_day_count": 0,
            "leave_count": 0,
            "absent_count": 0,
            "days_worked": 0.0,
            "regular_hours": 0,
            "overtime_hours": 0.0,
            "overtime_rate": float(ot_rate),
            "overtime_pay": 0.0
        }

    for a in att_records:
        if a.worker_id in worker_map:
            st = a.status
            if st == 'present':
                worker_map[a.worker_id]["present_count"] += 1
                worker_map[a.worker_id]["days_worked"] += 1.0
            elif st == 'late':
                worker_map[a.worker_id]["late_count"] += 1
                worker_map[a.worker_id]["days_worked"] += 1.0
            elif st == 'half_day':
                worker_map[a.worker_id]["half_day_count"] += 1
                worker_map[a.worker_id]["days_worked"] += 0.5
            elif st == 'leave':
                worker_map[a.worker_id]["leave_count"] += 1
                worker_map[a.worker_id]["days_worked"] += 1.0
            elif st == 'absent':
                worker_map[a.worker_id]["absent_count"] += 1

            worker_map[a.worker_id]["regular_hours"] += (a.regular_hours or 0)
            if a.overtime_hours and getattr(a, "is_overtime_verified", False):
                worker_map[a.worker_id]["overtime_hours"] += float(a.overtime_hours)

    for ot in ot_records:
        if ot.worker_id in worker_map and ot.is_verified:
            worker_map[ot.worker_id]["overtime_hours"] += float(ot.hours)

    for w_id, d in worker_map.items():
        d["overtime_pay"] = round(d["overtime_hours"] * d["overtime_rate"], 2)

    roster_list = sorted(list(worker_map.values()), key=lambda x: x["worker_name"])
    return {
        "site_id": site_id,
        "site_name": site_obj.name if site_obj else "",
        "period_start": str(date_from),
        "period_end": str(date_to),
        "total_workers": len(roster_list),
        "roster": roster_list
    }


@router.get("/attendance-roster/excel")
def export_attendance_roster_excel_endpoint(
    site_id: int,
    date_from: date = Query(..., description="Start date (YYYY-MM-DD)"),
    date_to: date = Query(..., description="End date (YYYY-MM-DD)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Download Attendance & Overtime Audit Ledger in Excel format
    """
    roster_resp = get_attendance_roster_report(site_id, date_from, date_to, db, current_user)
    period_str = f"{date_from} to {date_to}"
    excel_bytes = payment_export.export_attendance_roster_excel(roster_resp["roster"], period_str)

    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename=Attendance_Roster_{date_from}_{date_to}.xlsx"
        }
    )

