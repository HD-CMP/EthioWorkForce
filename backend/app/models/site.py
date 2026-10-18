from sqlalchemy import Column, Integer, String, Boolean, Float, ForeignKey
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Site(BaseModel):
    __tablename__ = "sites"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    code = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(String(1000), nullable=True)
    location_address = Column(String(500), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    site_admin_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    workers = relationship("Worker", back_populates="site", cascade="all, delete-orphan")
    attendances = relationship("Attendance", back_populates="site")
    overtimes = relationship("Overtime", back_populates="site")
    payrolls = relationship("Payroll", back_populates="site")
    user_assignments = relationship("UserSiteAssignment", back_populates="site", cascade="all, delete-orphan")
    payment_periods = relationship("PaymentPeriod", back_populates="site", cascade="all, delete-orphan")
