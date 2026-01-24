from pydantic import BaseModel
from typing import Optional, List
from decimal import Decimal
from datetime import date, datetime

from app.models.payroll import PayrollStatus, PayrollPeriodType


class PayrollItemData(BaseModel):
    worker_id: int
    days_worked: int
    regular_hours: int
    overtime_hours: int
    allowances: Decimal = Decimal("0")
    other_deductions: Decimal = Decimal("0")


class PayrollCreate(BaseModel):
    site_id: int
    period_type: PayrollPeriodType
    period_start: date
    period_end: date
    ethiopian_month: Optional[str] = None
    ethiopian_year: Optional[int] = None


class PayrollCalculate(BaseModel):
    payroll_id: int


class PayrollApprove(BaseModel):
    payroll_id: int
    notes: Optional[str] = None


class PayrollItemResponse(BaseModel):
    id: int
    payroll_id: int
    worker_id: int
    days_worked: int
    regular_hours: int
    overtime_hours: int
    base_salary: Decimal
    overtime_pay: Decimal
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

    class Config:
        from_attributes = True


class PayrollResponse(BaseModel):
    id: int
    payroll_code: str
    site_id: int
    period_type: PayrollPeriodType
    period_start: date
    period_end: date
    ethiopian_month: Optional[str] = None
    ethiopian_year: Optional[int] = None
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

    class Config:
        from_attributes = True
