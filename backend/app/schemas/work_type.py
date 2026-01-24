from pydantic import BaseModel, Field
from typing import Optional
from decimal import Decimal
from datetime import datetime

from app.models.work_type import PaymentMode, TaxRule


class WorkTypeBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    code: str = Field(..., min_length=1, max_length=50)
    description: Optional[str] = None
    payment_mode: PaymentMode
    base_rate: Decimal = Field(..., gt=0)
    tax_rule: TaxRule = TaxRule.STANDARD_EMPLOYEE
    overtime_eligible: bool = False
    overtime_multiplier: Optional[float] = 1.5
    pension_eligible: bool = True
    employee_pension_rate: Optional[float] = 0.07
    employer_pension_rate: Optional[float] = 0.11


class WorkTypeCreate(WorkTypeBase):
    pass


class WorkTypeUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    payment_mode: Optional[PaymentMode] = None
    base_rate: Optional[Decimal] = None
    tax_rule: Optional[TaxRule] = None
    overtime_eligible: Optional[bool] = None
    overtime_multiplier: Optional[float] = None
    pension_eligible: Optional[bool] = None
    employee_pension_rate: Optional[float] = None
    employer_pension_rate: Optional[float] = None
    is_active: Optional[bool] = None


class WorkTypeResponse(WorkTypeBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
