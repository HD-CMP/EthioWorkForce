from sqlalchemy import Column, Integer, String, Boolean, Float, Enum as SQLEnum, Numeric, Date
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class PaymentMode(str, enum.Enum):
    MONTHLY_SALARY = "monthly_salary"
    DAILY_RATE = "daily_rate"
    PIECE_RATE = "piece_rate"
    HOURLY_RATE = "hourly_rate"


class TaxRule(str, enum.Enum):
    STANDARD_EMPLOYEE = "standard_employee"
    DAILY_CASUAL = "daily_casual"


class HierarchyLevel(int, enum.Enum):
    EXECUTIVE = 1
    SENIOR_MANAGEMENT = 2
    MIDDLE_MANAGEMENT = 3
    SUPERVISORY = 4
    OPERATIONAL = 5
    TRAINEE = 6


class WorkType(BaseModel):
    __tablename__ = "work_types"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    code = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(String(1000), nullable=True)
    
    payment_mode = Column(SQLEnum(PaymentMode), nullable=False)
    base_rate = Column(Numeric(12, 2), nullable=False)
    payment_period_days = Column(Integer, nullable=True)
    payment_period_start_date = Column(Date, nullable=True)
    
    tax_rule = Column(SQLEnum(TaxRule), nullable=False, default=TaxRule.STANDARD_EMPLOYEE)
    
    overtime_eligible = Column(Boolean, default=False, nullable=False)
    overtime_rate_per_hour = Column(Numeric(10, 2), nullable=True)
    
    pension_eligible = Column(Boolean, default=True, nullable=False)
    employee_pension_rate = Column(Float, default=0.07, nullable=True)
    employer_pension_rate = Column(Float, default=0.11, nullable=True)
    
    hierarchy_level = Column(Integer, nullable=False, default=5)
    parent_work_type_id = Column(Integer, nullable=True)
    can_manage_levels = Column(String(50), nullable=True)
    requires_supervisor = Column(Boolean, default=True, nullable=False)
    max_subordinates = Column(Integer, nullable=True)
    
    is_active = Column(Boolean, default=True, nullable=False)
    
    workers = relationship("Worker", back_populates="work_type")
