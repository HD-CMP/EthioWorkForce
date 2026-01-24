from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class DisputeStatus(str, Enum):
    PENDING = "pending"
    UNDER_REVIEW = "under_review"
    RESOLVED = "resolved"
    REJECTED = "rejected"


class DisputeResolutionType(str, Enum):
    ATTENDANCE_CORRECTED = "attendance_corrected"
    ATTENDANCE_UPHELD = "attendance_upheld"
    PARTIAL_CORRECTION = "partial_correction"


class DisputeCreate(BaseModel):
    attendance_id: int
    dispute_reason: str = Field(..., min_length=20, max_length=1000)
    evidence_description: Optional[str] = Field(None, max_length=500)


class DisputeResolution(BaseModel):
    resolution: DisputeResolutionType
    resolution_notes: str = Field(..., min_length=10, max_length=1000)


class DisputeResponse(BaseModel):
    id: int
    attendance_id: int
    worker_id: int
    dispute_reason: str
    evidence_description: Optional[str]
    evidence_file_path: Optional[str]
    status: DisputeStatus
    resolution: Optional[DisputeResolutionType]
    resolution_notes: Optional[str]
    filed_by_user_id: int
    resolved_by_user_id: Optional[int]
    resolved_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
