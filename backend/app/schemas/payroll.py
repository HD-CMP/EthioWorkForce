from pydantic import BaseModel
from typing import Optional, List
from decimal import Decimal
from datetime import date, datetime

from app.models.payroll import PayrollStatus, PayrollPeriodType


class PayrollItemData(BaseModel):
    worker_id: int
    days_worked: int
    regular_hours: int
    overtime_hours: float
    allowances: Decimal = Decimal("0")
    other_deductions: Decimal = Decimal("0")


class PayrollCreate(BaseModel):
    site_id: int
    period_type: PayrollPeriodType
    period_start: date
    period_end: date
    ethiopian_month: Optional[str] = None
    ethiopian_year: Optional[int] = None
    work_type_id: Optional[int] = None
    work_place_id: Optional[int] = None


class PayrollCalculate(BaseModel):
    payroll_id: int


class PayrollApprove(BaseModel):
    payroll_id: int
    notes: Optional[str] = None


class PayrollItemResponse(BaseModel):
    id: int
    payroll_id: int
    worker_id: int
    worker_name: Optional[str] = None
    employee_id: Optional[str] = None
    work_type_id: Optional[int] = None
    work_type_name: Optional[str] = None
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    phone_number: Optional[str] = None
    
    # Payment period metadata
    payment_period_start: Optional[date] = None
    payment_period_end: Optional[date] = None
    payment_period_days: Optional[int] = None
    is_prorated: bool = False
    payment_period_type: Optional[str] = None
    payment_period_description: Optional[str] = None
    
    days_worked: int
    regular_hours: int
    overtime_hours: float
    base_salary: Decimal
    overtime_pay: Decimal
    allocated_overtime_pay: Decimal
    allowances: Decimal
    gross_salary: Decimal
    income_tax: Decimal
    employee_pension: Decimal
    employer_pension: Decimal
    cost_sharing: Decimal
    other_deductions: Decimal
    total_deductions: Decimal
    net_salary: Decimal
    tax_rule_applied: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    # Payment status
    is_paid: bool = False
    payment_date: Optional[date] = None
    payment_id: Optional[int] = None

    class Config:
        from_attributes = True
        json_encoders = {
            Decimal: lambda v: float(v)
        }


class PayrollResponse(BaseModel):
    id: int
    payroll_code: str
    site_id: int
    period_type: PayrollPeriodType
    period_start: date
    period_end: date
    ethiopian_month: Optional[str] = None
    ethiopian_year: Optional[int] = None
    work_type_id: Optional[int] = None
    work_place_id: Optional[int] = None
    total_gross_amount: Decimal
    total_deductions: Decimal
    total_net_amount: Decimal
    total_employer_pension: Decimal
    status: PayrollStatus
    calculated_by_id: Optional[int] = None
    approved_by_id: Optional[int] = None
    approved_at: Optional[date] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    payroll_items: Optional[List[PayrollItemResponse]] = None
    has_multiple_periods: Optional[bool] = None
    period_types_count: Optional[int] = None

    class Config:
        from_attributes = True
        json_encoders = {
            Decimal: lambda v: float(v)
        }
