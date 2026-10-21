from sqlalchemy import Column, Integer, String, Boolean, Enum as SQLEnum, ForeignKey
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class UserRole(str, enum.Enum):
    SUPER_ADMIN = "super_admin"
    ADMIN = "admin"
    SITE_ADMIN = "site_admin"
    SUPERVISOR = "supervisor"
    HR_OFFICER = "hr_officer"
    VIEWER = "viewer"


class User(BaseModel):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    full_name = Column(String(255), nullable=False)
    phone_number = Column(String(20), nullable=True)
    hashed_password = Column(String(255), nullable=False)
    role = Column(SQLEnum(UserRole), nullable=False, default=UserRole.VIEWER)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    profile_photo = Column(String(500), nullable=True)
    preferred_language = Column(String(5), default="en", nullable=False)
    
    # Unified Identity: Links software login user to physical employee/worker record
    worker_id = Column(Integer, ForeignKey("workers.id", ondelete="SET NULL"), nullable=True, unique=True, index=True)
    
    audit_logs = relationship("AuditLog", back_populates="user")
    site_assignments = relationship("UserSiteAssignment", back_populates="user", cascade="all, delete-orphan")
    work_place_assignments = relationship("UserWorkPlaceAssignment", back_populates="user", cascade="all, delete-orphan")
    worker = relationship("Worker", back_populates="user_account", foreign_keys=[worker_id])
