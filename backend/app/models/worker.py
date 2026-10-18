from sqlalchemy import Column, Integer, String, Boolean, Date, ForeignKey, Enum as SQLEnum, Numeric, UniqueConstraint
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class WorkerStatus(str, enum.Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    TERMINATED = "terminated"
    SUSPENDED = "suspended"


class CalendarPreference(str, enum.Enum):
    GREGORIAN = "gregorian"
    ETHIOPIAN = "ethiopian"


class Worker(BaseModel):
    __tablename__ = "workers"
    __table_args__ = (
        UniqueConstraint('employee_id', 'site_id', 'work_type_id', name='uq_worker_employee_id_site_work_type'),
    )

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(String(50), nullable=False, index=True)
    
    full_name = Column(String(255), nullable=False, index=True)
    photo_url = Column(String(500), nullable=True)
    phone_number = Column(String(20), nullable=True)
    national_id = Column(String(50), nullable=True, unique=True)
    
    date_of_birth = Column(Date, nullable=True)
    gender = Column(String(10), nullable=True)
    
    site_id = Column(Integer, ForeignKey("sites.id"), nullable=False)
    work_place_id = Column(Integer, ForeignKey("work_places.id"), nullable=True)
    work_type_id = Column(Integer, ForeignKey("work_types.id"), nullable=False)
    supervisor_id = Column(Integer, ForeignKey("workers.id"), nullable=True)
    
    hire_date = Column(Date, nullable=False)
    base_salary = Column(Numeric(12, 2), nullable=True)
    termination_date = Column(Date, nullable=True)
    
    status = Column(SQLEnum(WorkerStatus), default=WorkerStatus.ACTIVE, nullable=False)
    calendar_preference = Column(
        SQLEnum(CalendarPreference),
        default=CalendarPreference.GREGORIAN,
        nullable=False
    )
    
    bank_name = Column(String(100), nullable=True)
    bank_account_number = Column(String(50), nullable=True)
    emergency_contact_name = Column(String(255), nullable=True)
    emergency_contact_phone = Column(String(20), nullable=True)
    
    overtime_hours = Column(Numeric(6, 2), nullable=True, default=0)
    overtime_rate_per_hour = Column(Numeric(10, 2), nullable=True, default=0)
    
    payment_period_days = Column(Integer, nullable=True, default=14)
    
    qr_code = Column(String(500), nullable=True)
    
    site = relationship("Site", back_populates="workers")
    work_place = relationship("WorkPlace", foreign_keys=[work_place_id], backref="workers")
    work_type = relationship("WorkType", back_populates="workers")
    supervisor = relationship("Worker", remote_side=[id], foreign_keys=[supervisor_id], backref="subordinates")
    attendances = relationship("Attendance", back_populates="worker", cascade="all, delete-orphan")
    overtimes = relationship("Overtime", back_populates="worker", cascade="all, delete-orphan")
    payroll_items = relationship("PayrollItem", back_populates="worker")
    leaves = relationship("Leave", back_populates="worker", cascade="all, delete-orphan")
    role_changes = relationship("RoleChange", back_populates="worker", cascade="all, delete-orphan")
    disputes = relationship("AttendanceDispute", back_populates="worker", cascade="all, delete-orphan")
