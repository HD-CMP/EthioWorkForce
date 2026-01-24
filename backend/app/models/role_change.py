from sqlalchemy import Column, Integer, String, Date, ForeignKey, Enum as SQLEnum, Text
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class RoleChangeStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    IMPLEMENTED = "implemented"


class RoleChange(BaseModel):
    __tablename__ = "role_changes"

    id = Column(Integer, primary_key=True, index=True)
    worker_id = Column(Integer, ForeignKey("workers.id"), nullable=False)
    old_work_type_id = Column(Integer, ForeignKey("work_types.id"), nullable=False)
    new_work_type_id = Column(Integer, ForeignKey("work_types.id"), nullable=False)
    old_site_id = Column(Integer, ForeignKey("sites.id"), nullable=True)
    new_site_id = Column(Integer, ForeignKey("sites.id"), nullable=True)
    effective_date = Column(Date, nullable=False)
    reason = Column(Text, nullable=False)
    status = Column(SQLEnum(RoleChangeStatus), default=RoleChangeStatus.PENDING, nullable=False)
    requested_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    approved_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    implemented_at = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    
    worker = relationship("Worker", back_populates="role_changes")
    old_work_type = relationship("WorkType", foreign_keys=[old_work_type_id])
    new_work_type = relationship("WorkType", foreign_keys=[new_work_type_id])
    old_site = relationship("Site", foreign_keys=[old_site_id])
    new_site = relationship("Site", foreign_keys=[new_site_id])
    requested_by = relationship("User", foreign_keys=[requested_by_user_id])
    approved_by = relationship("User", foreign_keys=[approved_by_user_id])
