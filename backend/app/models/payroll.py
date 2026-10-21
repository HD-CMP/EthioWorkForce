from sqlalchemy import Column, Integer, String, Date, ForeignKey, Enum as SQLEnum, Numeric, Boolean, Text, Float
from sqlalchemy.orm import relationship
from typing import Optional
import enum

from app.models.base import BaseModel


class PayrollStatus(str, enum.Enum):
    DRAFT = "draft"
    CALCULATED = "calculated"
    APPROVED = "approved"
    PAID = "paid"
    CANCELLED = "cancelled"


class PayrollPeriodType(str, enum.Enum):
    MONTHLY = "monthly"
    WEEKLY = "weekly"
    BI_WEEKLY = "bi_weekly"
    CUSTOM = "custom"


class Payroll(BaseModel):
    __tablename__ = "payrolls"

    id = Column(Integer, primary_key=True, index=True)
    
    payroll_code = Column(String(50), unique=True, nullable=False, index=True)
    site_id = Column(Integer, ForeignKey("sites.id"), nullable=False)
    
    period_type = Column(SQLEnum(PayrollPeriodType), nullable=False)
    period_start = Column(Date, nullable=False, index=True)
    period_end = Column(Date, nullable=False, index=True)
    
    ethiopian_month = Column(String(50), nullable=True)
    ethiopian_year = Column(Integer, nullable=True)
    
    total_gross_amount = Column(Numeric(15, 2), default=0, nullable=False)
    total_deductions = Column(Numeric(15, 2), default=0, nullable=False)
    total_net_amount = Column(Numeric(15, 2), default=0, nullable=False)
    total_employer_pension = Column(Numeric(15, 2), default=0, nullable=False)
    
    status = Column(SQLEnum(PayrollStatus), default=PayrollStatus.DRAFT, nullable=False)
    
    calculated_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved_at = Column(Date, nullable=True)
    
    notes = Column(Text, nullable=True)
    work_type_id = Column(Integer, ForeignKey("work_types.id"), nullable=True)
    work_place_id = Column(Integer, ForeignKey("work_places.id"), nullable=True)
    
    site = relationship("Site", back_populates="payrolls")
    payroll_items = relationship("PayrollItem", back_populates="payroll", cascade="all, delete-orphan")


class PayrollItem(BaseModel):
    __tablename__ = "payroll_items"

    id = Column(Integer, primary_key=True, index=True)
    
    payroll_id = Column(Integer, ForeignKey("payrolls.id"), nullable=False)
    worker_id = Column(Integer, ForeignKey("workers.id"), nullable=False)
    
    # Payment period metadata
    payment_period_start = Column(Date, nullable=True)
    payment_period_end = Column(Date, nullable=True)
    payment_period_days = Column(Integer, nullable=True)
    is_prorated = Column(Boolean, default=False, nullable=False)
    payment_period_type = Column(String(50), nullable=True)
    
    days_worked = Column(Integer, default=0, nullable=False)
    regular_hours = Column(Integer, default=0, nullable=False)
    overtime_hours = Column(Float, default=0.0, nullable=False)
    
    base_salary = Column(Numeric(12, 2), default=0, nullable=False)
    overtime_pay = Column(Numeric(12, 2), default=0, nullable=False)
    allocated_overtime_pay = Column(Numeric(12, 2), default=0, nullable=False)
    allowances = Column(Numeric(12, 2), default=0, nullable=False)
    
    gross_salary = Column(Numeric(12, 2), default=0, nullable=False)
    
    income_tax = Column(Numeric(12, 2), default=0, nullable=False)
    employee_pension = Column(Numeric(12, 2), default=0, nullable=False)
    employer_pension = Column(Numeric(12, 2), default=0, nullable=False)
    cost_sharing = Column(Numeric(12, 2), default=0, nullable=False)
    other_deductions = Column(Numeric(12, 2), default=0, nullable=False)
    
    total_deductions = Column(Numeric(12, 2), default=0, nullable=False)
    net_salary = Column(Numeric(12, 2), default=0, nullable=False)
    
    tax_rule_applied = Column(String(50), nullable=True)
    
    notes = Column(Text, nullable=True)
    
    payroll = relationship("Payroll", back_populates="payroll_items")
    worker = relationship("Worker", back_populates="payroll_items")
    payment = relationship("Payment", back_populates="payroll_item", uselist=False)

    @property
    def worker_name(self) -> Optional[str]:
        return self.worker.full_name if self.worker else None

    @property
    def employee_id(self) -> Optional[str]:
        return self.worker.employee_id if self.worker else None

    @property
    def work_type_id(self) -> Optional[int]:
        return self.worker.work_type_id if self.worker else None

    @property
    def work_type_name(self) -> Optional[str]:
        return self.worker.work_type.name if (self.worker and self.worker.work_type) else None

    @property
    def bank_name(self) -> Optional[str]:
        return self.worker.bank_name if self.worker else None

    @property
    def bank_account_number(self) -> Optional[str]:
        return self.worker.bank_account_number if self.worker else None

    @property
    def phone_number(self) -> Optional[str]:
        return self.worker.phone_number if self.worker else None

    @property
    def is_paid(self) -> bool:
        if self.payment and getattr(self.payment, 'status', None) == 'completed':
            return True
        if self.notes and "Payment status: PAID" in self.notes:
            return True
        return False

    @property
    def payment_date(self) -> Optional[Date]:
        if self.payment and getattr(self.payment, 'payment_date', None):
            return self.payment.payment_date
        return None

    @property
    def payment_id(self) -> Optional[int]:
        if self.payment:
            return self.payment.id
        return None

    @property
    def payment_period_description(self) -> Optional[str]:
        if self.payment_period_start and self.payment_period_end:
            return f"{self.payment_period_start.strftime('%d/%m/%Y')} - {self.payment_period_end.strftime('%d/%m/%Y')}"
        return None
