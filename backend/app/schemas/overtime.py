from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime


class OvertimeBase(BaseModel):
    worker_id: int
    site_id: int
    overtime_date: date
    hours: float
    notes: Optional[str] = None


class OvertimeCreate(OvertimeBase):
    pass


class OvertimeUpdate(BaseModel):
    hours: Optional[float] = None
    notes: Optional[str] = None


class OvertimeResponse(BaseModel):
    id: int
    worker_id: int
    worker_name: Optional[str] = None
    employee_id: Optional[str] = None
    site_id: int
    overtime_date: date
    hours: float
    is_verified: bool
    verified_by_id: Optional[int] = None
    verified_at: Optional[datetime] = None
    is_locked: bool
    notes: Optional[str] = None
    ethiopian_date_year: Optional[int] = None
    ethiopian_date_month: Optional[int] = None
    ethiopian_date_day: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OvertimeEntry(BaseModel):
    worker_id: int
    hours: float


class OvertimeBulkCreate(BaseModel):
    site_id: int
    overtime_date: date
    entries: list[OvertimeEntry]
    verify: bool = False


class OvertimeVerify(BaseModel):
    site_id: int
    overtime_ids: list[int]


class MultiDayOvertimeEntry(BaseModel):
    overtime_date: date
    hours: float


class MultiDayOvertimeCreate(BaseModel):
    worker_id: int
    site_id: int
    entries: list[MultiDayOvertimeEntry]
    verify: bool = False
