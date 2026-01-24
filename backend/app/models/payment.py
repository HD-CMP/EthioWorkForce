from sqlalchemy import Column, Integer, String, Date, ForeignKey, Enum as SQLEnum, Numeric, Boolean, Text
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class PaymentMethod(str, enum.Enum):
    CASH = "cash"
    BANK_TRANSFER = "bank_transfer"
    TELEBIRR = "telebirr"
    MPESA = "mpesa"
    MOBILE_MONEY = "mobile_money"


class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class Payment(BaseModel):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    
    payment_code = Column(String(50), unique=True, nullable=False, index=True)
    payroll_item_id = Column(Integer, ForeignKey("payroll_items.id"), nullable=False)
    
    amount = Column(Numeric(12, 2), nullable=False)
    payment_method = Column(SQLEnum(PaymentMethod), nullable=False)
    payment_date = Column(Date, nullable=True)
    
    status = Column(SQLEnum(PaymentStatus), default=PaymentStatus.PENDING, nullable=False)
    
    bank_name = Column(String(100), nullable=True)
    account_number = Column(String(50), nullable=True)
    transaction_reference = Column(String(100), nullable=True)
    
    signature_url = Column(String(500), nullable=True)
    receipt_url = Column(String(500), nullable=True)
    
    processed_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    notes = Column(Text, nullable=True)
    
    payroll_item = relationship("PayrollItem", back_populates="payment")
