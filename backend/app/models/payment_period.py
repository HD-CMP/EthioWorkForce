from sqlalchemy import Column, Integer, String, Date, ForeignKey, Boolean, Enum as SQLEnum
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class PeriodStatus(str, enum.Enum):
    ACTIVE = "active"
    CLOSED = "closed"
    LOCKED = "locked"


class PaymentPeriod(BaseModel):
    __tablename__ = "payment_periods"

    id = Column(Integer, primary_key=True, index=True)
    
    site_id = Column(Integer, ForeignKey("sites.id"), nullable=False)
    period_start = Column(Date, nullable=False, index=True)
    period_end = Column(Date, nullable=False, index=True)
    period_days = Column(Integer, nullable=False)
    
    status = Column(SQLEnum(PeriodStatus, native_enum=True, values_callable=lambda x: [e.value for e in x]), default=PeriodStatus.ACTIVE, nullable=False)
    is_current = Column(Boolean, default=False, nullable=False)
    
    ethiopian_start_year = Column(Integer, nullable=True)
    ethiopian_start_month = Column(Integer, nullable=True)
    ethiopian_start_day = Column(Integer, nullable=True)
    ethiopian_end_year = Column(Integer, nullable=True)
    ethiopian_end_month = Column(Integer, nullable=True)
    ethiopian_end_day = Column(Integer, nullable=True)
    
    site = relationship("Site", back_populates="payment_periods")
