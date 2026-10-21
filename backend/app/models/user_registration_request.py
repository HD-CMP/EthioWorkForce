from sqlalchemy import Column, Integer, String, Boolean, Enum as SQLEnum, ForeignKey, Text, DateTime, JSON
from sqlalchemy.orm import relationship
import enum
from datetime import datetime

from app.models.base import BaseModel


class RequestStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    CANCELLED = "cancelled"


class UserRegistrationRequest(BaseModel):
    __tablename__ = "user_registration_requests"

    id = Column(Integer, primary_key=True, index=True)
    
    username = Column(String(100), nullable=False)
    email = Column(String(255), nullable=True)
    full_name = Column(String(255), nullable=False)
    phone_number = Column(String(20), nullable=True)
    role = Column(String(50), nullable=False)
    preferred_language = Column(String(5), default="en", nullable=False)
    
    hashed_password = Column(String(255), nullable=False)
    
    requested_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    approved_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    status = Column(SQLEnum(RequestStatus), default=RequestStatus.PENDING, nullable=False, index=True)
    
    request_reason = Column(Text, nullable=True)
    approval_notes = Column(Text, nullable=True)
    
    site_ids = Column(JSON, nullable=True)
    work_place_ids = Column(JSON, nullable=True)
    
    # Linked physical worker (for employee account provisioning)
    worker_id = Column(Integer, ForeignKey("workers.id", ondelete="SET NULL"), nullable=True, index=True)
    
    reviewed_at = Column(DateTime, nullable=True)
    
    requested_by = relationship("User", foreign_keys=[requested_by_id], backref="registration_requests")
    approved_by = relationship("User", foreign_keys=[approved_by_id])
    worker = relationship("Worker", foreign_keys=[worker_id])
