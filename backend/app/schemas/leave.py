from pydantic import BaseModel, Field
from datetime import date
from typing import Optional
from enum import Enum


class LeaveType(str, Enum):
    ANNUAL = "annual"
    SICK = "sick"
    UNPAID = "unpaid"
    MATERNITY = "maternity"
    PATERNITY = "paternity"
    EMERGENCY = "emergency"
    COMPASSIONATE = "compassionate"


class LeaveStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    CANCELLED = "cancelled"


class LeaveCreate(BaseModel):
    worker_id: int
    leave_type: LeaveType
    start_date: date
    end_date: date
    reason: str = Field(..., min_length=10, max_length=500)


class LeaveUpdate(BaseModel):
    reason: Optional[str] = Field(None, min_length=10, max_length=500)


class LeaveApproval(BaseModel):
    approved: bool
    rejection_reason: Optional[str] = Field(None, min_length=10, max_length=500)


class LeaveResponse(BaseModel):
    id: int
    worker_id: int
    leave_type: LeaveType
    status: LeaveStatus
    start_date: date
    end_date: date
    days_count: int
    reason: str
    rejection_reason: Optional[str]
    requested_by_user_id: int
    approved_by_user_id: Optional[int]
    approved_at: Optional[date]
    created_at: date
    updated_at: date

    class Config:
        from_attributes = True
