from sqlalchemy import Column, Integer, ForeignKey, Boolean
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class UserWorkPlaceAssignment(BaseModel):
    __tablename__ = "user_work_place_assignments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    work_place_id = Column(Integer, ForeignKey("work_places.id", ondelete="CASCADE"), nullable=False)
    is_primary = Column(Boolean, default=False, nullable=False)
    
    user = relationship("User", back_populates="work_place_assignments")
    work_place = relationship("WorkPlace", backref="user_assignments")
