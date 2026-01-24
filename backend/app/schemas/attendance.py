from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, time, datetime

from app.models.attendance import AttendanceStatus, AttendanceMethod


class AttendanceBase(BaseModel):
    worker_id: int
    site_id: int
    attendance_date: date
    check_in_time: Optional[time] = None
    check_out_time: Optional[time] = None
    status: AttendanceStatus
    method: AttendanceMethod
    regular_hours: int = 8
    overtime_hours: int = 0
    notes: Optional[str] = None


class AttendanceCreate(AttendanceBase):
    pass


class AttendanceBulkCreate(BaseModel):
    site_id: int
    attendance_date: date
    worker_ids: list[int]
    method: AttendanceMethod = AttendanceMethod.MANUAL_ENTRY
    status: AttendanceStatus = AttendanceStatus.PRESENT
    check_in_time: Optional[time] = None


class AttendanceUpdate(BaseModel):
    check_in_time: Optional[time] = None
    check_out_time: Optional[time] = None
    status: Optional[AttendanceStatus] = None
    regular_hours: Optional[int] = None
    overtime_hours: Optional[int] = None
    override_reason: Optional[str] = None
    notes: Optional[str] = None


class AttendanceVerify(BaseModel):
    attendance_ids: list[int]
    override_reason: Optional[str] = None


class AttendanceResponse(AttendanceBase):
    id: int
    is_verified: bool
    verified_by_id: Optional[int] = None
    verified_at: Optional[datetime] = None
    override_reason: Optional[str] = None
    ethiopian_date_year: Optional[int] = None
    ethiopian_date_month: Optional[int] = None
    ethiopian_date_day: Optional[int] = None
    is_locked: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
