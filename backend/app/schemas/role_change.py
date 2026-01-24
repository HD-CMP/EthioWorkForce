from pydantic import BaseModel, Field
from datetime import date
from typing import Optional
from enum import Enum


class RoleChangeStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    IMPLEMENTED = "implemented"


class RoleChangeCreate(BaseModel):
    worker_id: int
    new_work_type_id: int
    new_site_id: Optional[int] = None
    effective_date: date
    reason: str = Field(..., min_length=10, max_length=500)


class RoleChangeApproval(BaseModel):
    approved: bool
    notes: Optional[str] = Field(None, max_length=500)


class RoleChangeResponse(BaseModel):
    id: int
    worker_id: int
    old_work_type_id: int
    new_work_type_id: int
    old_site_id: Optional[int]
    new_site_id: Optional[int]
    effective_date: date
    reason: str
    status: RoleChangeStatus
    requested_by_user_id: int
    approved_by_user_id: Optional[int]
    implemented_at: Optional[date]
    notes: Optional[str]
    created_at: date
    updated_at: date

    class Config:
        from_attributes = True
