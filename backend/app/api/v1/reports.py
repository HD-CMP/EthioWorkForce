from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
import io

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.payroll import Payroll, PayrollItem
from app.models.worker import Worker
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
