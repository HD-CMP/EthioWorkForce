from sqlalchemy import Column, Integer, String, Boolean, Date, DateTime, Time, ForeignKey, Enum as SQLEnum, Text, Float
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class AttendanceStatus(str, enum.Enum):
    PRESENT = "present"
    ABSENT = "absent"
    LATE = "late"
    EXCUSED = "excused"
    LEAVE = "leave"
    HALF_DAY = "half_day"


class AttendanceMethod(str, enum.Enum):
    QR_SCAN = "qr_scan"
    MANUAL_ENTRY = "manual_entry"
    BIOMETRIC = "biometric"
    MOBILE_APP = "mobile_app"


class Attendance(BaseModel):
    __tablename__ = "attendances"

    id = Column(Integer, primary_key=True, index=True)
    
    worker_id = Column(Integer, ForeignKey("workers.id"), nullable=False)
    site_id = Column(Integer, ForeignKey("sites.id"), nullable=False)
    
    attendance_date = Column(Date, nullable=False, index=True)
    check_in_time = Column(Time, nullable=True)
    check_out_time = Column(Time, nullable=True)
    
    status = Column(SQLEnum(AttendanceStatus), nullable=False)
    method = Column(SQLEnum(AttendanceMethod), nullable=False)
    
    regular_hours = Column(Integer, default=8, nullable=False)
    overtime_hours = Column(Float, default=0.0, nullable=False)
    
    is_verified = Column(Boolean, default=False, nullable=False)
    verified_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    verified_at = Column(DateTime, nullable=True)
    
    is_overtime_verified = Column(Boolean, default=False, nullable=False)
    overtime_verified_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    overtime_verified_at = Column(DateTime, nullable=True)
    
    override_reason = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    
    ethiopian_date_year = Column(Integer, nullable=True)
    ethiopian_date_month = Column(Integer, nullable=True)
    ethiopian_date_day = Column(Integer, nullable=True)
    
    is_locked = Column(Boolean, default=False, nullable=False)
    is_overtime_locked = Column(Boolean, default=False, nullable=False)
    
    worker = relationship("Worker", back_populates="attendances")
    site = relationship("Site", back_populates="attendances")
    disputes = relationship("AttendanceDispute", back_populates="attendance", cascade="all, delete-orphan")
