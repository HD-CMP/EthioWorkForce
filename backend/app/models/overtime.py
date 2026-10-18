from sqlalchemy import Column, Integer, Float, Date, Boolean, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Overtime(BaseModel):
    __tablename__ = "overtimes"

    id = Column(Integer, primary_key=True, index=True)
    
    worker_id = Column(Integer, ForeignKey("workers.id"), nullable=False)
    site_id = Column(Integer, ForeignKey("sites.id"), nullable=False)
    
    overtime_date = Column(Date, nullable=False, index=True)
    hours = Column(Float, nullable=False)
    
    is_verified = Column(Boolean, default=False, nullable=False)
    verified_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    verified_at = Column(DateTime, nullable=True)
    
    is_locked = Column(Boolean, default=False, nullable=False)
    
    notes = Column(Text, nullable=True)
    
    ethiopian_date_year = Column(Integer, nullable=True)
    ethiopian_date_month = Column(Integer, nullable=True)
    ethiopian_date_day = Column(Integer, nullable=True)
    
    worker = relationship("Worker", back_populates="overtimes")
    site = relationship("Site", back_populates="overtimes")
    verified_by = relationship("User", foreign_keys=[verified_by_id])
