from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime

from app.models.worker import WorkerStatus, CalendarPreference


class WorkerBase(BaseModel):
    employee_id: str = Field(..., min_length=1, max_length=50)
    full_name: str = Field(..., min_length=1, max_length=255)
    phone_number: Optional[str] = None
    national_id: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    site_id: int
    work_type_id: int
    hire_date: date
    calendar_preference: CalendarPreference = CalendarPreference.GREGORIAN
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class WorkerCreate(WorkerBase):
    pass


class WorkerUpdate(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    national_id: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    site_id: Optional[int] = None
    work_type_id: Optional[int] = None
    status: Optional[WorkerStatus] = None
    termination_date: Optional[date] = None
    calendar_preference: Optional[CalendarPreference] = None
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class WorkerResponse(WorkerBase):
    id: int
    photo_url: Optional[str] = None
    status: WorkerStatus
    termination_date: Optional[date] = None
    qr_code: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
