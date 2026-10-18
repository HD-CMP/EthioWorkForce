from pydantic import BaseModel, Field
from typing import Optional, List
from decimal import Decimal
from datetime import datetime, date

from app.models.work_type import PaymentMode, TaxRule


class WorkTypeBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    code: str = Field(..., min_length=1, max_length=50)
    description: Optional[str] = None
    payment_mode: PaymentMode
    base_rate: Decimal = Field(..., gt=0)
    payment_period_days: Optional[int] = Field(default=None, ge=1, le=365, description="Number of days in payment period (e.g., 14 for bi-weekly, 30 for monthly)")
    payment_period_start_date: Optional[date] = Field(default=None, description="Fixed start date for payment period calculations - ensures consistent periods")
    tax_rule: TaxRule = TaxRule.STANDARD_EMPLOYEE
    overtime_eligible: bool = False
    overtime_rate_per_hour: Optional[Decimal] = None
    pension_eligible: bool = True
    employee_pension_rate: Optional[float] = 0.07
    employer_pension_rate: Optional[float] = 0.11
    hierarchy_level: int = Field(default=5, ge=1, le=6, description="Organizational hierarchy level (1=Executive, 6=Trainee)")
    parent_work_type_id: Optional[int] = Field(default=None, description="Parent work type in hierarchy")
    can_manage_levels: Optional[str] = Field(default=None, description="Comma-separated list of hierarchy levels this role can manage")
    requires_supervisor: bool = Field(default=True, description="Whether workers in this role require a supervisor")
    max_subordinates: Optional[int] = Field(default=None, ge=1, description="Maximum number of direct reports allowed")


class WorkTypeCreate(WorkTypeBase):
    pass


class WorkTypeUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    payment_mode: Optional[PaymentMode] = None
    base_rate: Optional[Decimal] = None
    payment_period_days: Optional[int] = Field(default=None, ge=1, le=365)
    payment_period_start_date: Optional[date] = None
    tax_rule: Optional[TaxRule] = None
    overtime_eligible: Optional[bool] = None
    overtime_rate_per_hour: Optional[Decimal] = None
    pension_eligible: Optional[bool] = None
    employee_pension_rate: Optional[float] = None
    employer_pension_rate: Optional[float] = None
    hierarchy_level: Optional[int] = Field(default=None, ge=1, le=6)
    parent_work_type_id: Optional[int] = None
    can_manage_levels: Optional[str] = None
    requires_supervisor: Optional[bool] = None
    max_subordinates: Optional[int] = Field(default=None, ge=1)
    is_active: Optional[bool] = None


class WorkTypeResponse(WorkTypeBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
