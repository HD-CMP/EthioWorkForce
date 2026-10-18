from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime

from app.models.payment_period import PeriodStatus


class PaymentPeriodBase(BaseModel):
    site_id: int
    period_start: date
    period_end: date
    period_days: int


class PaymentPeriodCreate(PaymentPeriodBase):
    ethiopian_start_year: Optional[int] = None
    ethiopian_start_month: Optional[int] = None
    ethiopian_start_day: Optional[int] = None
    ethiopian_end_year: Optional[int] = None
    ethiopian_end_month: Optional[int] = None
    ethiopian_end_day: Optional[int] = None


class PaymentPeriodUpdate(BaseModel):
    status: Optional[PeriodStatus] = None
    is_current: Optional[bool] = None


class PaymentPeriodResponse(PaymentPeriodBase):
    id: int
    status: PeriodStatus
    is_current: bool
    ethiopian_start_year: Optional[int] = None
    ethiopian_start_month: Optional[int] = None
    ethiopian_start_day: Optional[int] = None
    ethiopian_end_year: Optional[int] = None
    ethiopian_end_month: Optional[int] = None
    ethiopian_end_day: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
