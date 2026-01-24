from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SQLEnum, Text
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class DisputeStatus(str, enum.Enum):
    PENDING = "pending"
    UNDER_REVIEW = "under_review"
    RESOLVED = "resolved"
    REJECTED = "rejected"


class DisputeResolution(str, enum.Enum):
    ATTENDANCE_CORRECTED = "attendance_corrected"
    ATTENDANCE_UPHELD = "attendance_upheld"
    PARTIAL_CORRECTION = "partial_correction"


class AttendanceDispute(BaseModel):
    __tablename__ = "attendance_disputes"

    id = Column(Integer, primary_key=True, index=True)
    attendance_id = Column(Integer, ForeignKey("attendances.id"), nullable=False)
    worker_id = Column(Integer, ForeignKey("workers.id"), nullable=False)
    dispute_reason = Column(Text, nullable=False)
    evidence_description = Column(Text, nullable=True)
    evidence_file_path = Column(String(500), nullable=True)
    status = Column(SQLEnum(DisputeStatus), default=DisputeStatus.PENDING, nullable=False)
    resolution = Column(SQLEnum(DisputeResolution), nullable=True)
    resolution_notes = Column(Text, nullable=True)
    filed_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    resolved_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    resolved_at = Column(DateTime, nullable=True)
    
    attendance = relationship("Attendance", back_populates="disputes")
    worker = relationship("Worker", back_populates="disputes")
    filed_by = relationship("User", foreign_keys=[filed_by_user_id])
    resolved_by = relationship("User", foreign_keys=[resolved_by_user_id])
