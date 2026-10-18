from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime
from decimal import Decimal

from app.models.worker import WorkerStatus, CalendarPreference


class WorkerBase(BaseModel):
    employee_id: str = Field(..., min_length=1, max_length=50)
    full_name: str = Field(..., min_length=1, max_length=255)
    phone_number: Optional[str] = None
    national_id: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    site_id: int
    work_place_id: Optional[int] = Field(default=None, description="ID of the work place within the site")
    work_type_id: int
    supervisor_id: Optional[int] = Field(default=None, description="ID of the supervisor/manager this worker reports to")
    hire_date: date
    calendar_preference: CalendarPreference = CalendarPreference.GREGORIAN
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    overtime_hours: Optional[Decimal] = Field(default=0, ge=0, description="Monthly overtime hours for this worker")
    overtime_rate_per_hour: Optional[Decimal] = Field(default=0, ge=0, description="Hourly rate for overtime payment")
    payment_period_days: Optional[int] = Field(default=14, ge=1, le=31, description="Payment period length in days (7, 14, or 30)")
    base_salary: Optional[Decimal] = Field(default=None, ge=0, description="Individual base salary for hierarchy level 1-4 workers. Overrides WorkType base_rate in payroll.")


class WorkerCreate(WorkerBase):
    pass


class WorkerUpdate(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    national_id: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    site_id: Optional[int] = None
    work_place_id: Optional[int] = None
    work_type_id: Optional[int] = None
    supervisor_id: Optional[int] = None
    status: Optional[WorkerStatus] = None
    termination_date: Optional[date] = None
    calendar_preference: Optional[CalendarPreference] = None
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    overtime_hours: Optional[Decimal] = Field(default=None, ge=0)
    overtime_rate_per_hour: Optional[Decimal] = Field(default=None, ge=0)
    payment_period_days: Optional[int] = Field(default=None, ge=1, le=31)
    base_salary: Optional[Decimal] = Field(default=None, ge=0, description="Individual base salary for hierarchy level 1-4 workers.")


class WorkerResponse(WorkerBase):
    id: int
    photo_url: Optional[str] = None
    status: WorkerStatus
    termination_date: Optional[date] = None
    qr_code: Optional[str] = None
    supervisor_name: Optional[str] = Field(default=None, description="Name of the supervisor")
    site_name: Optional[str] = Field(default=None, description="Name of the site")
    work_place_name: Optional[str] = Field(default=None, description="Name of the work place")
    work_place_supervisor_name: Optional[str] = Field(default=None, description="Name of the work place supervisor")
    work_type: Optional[str] = Field(default=None, description="Name of the work type")
    hierarchy_level: Optional[int] = Field(default=None, description="Hierarchy level from work type")
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
