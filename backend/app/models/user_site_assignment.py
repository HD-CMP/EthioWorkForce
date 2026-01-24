from sqlalchemy import Column, Integer, ForeignKey, Boolean, Table
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class UserSiteAssignment(BaseModel):
    __tablename__ = "user_site_assignments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    site_id = Column(Integer, ForeignKey("sites.id", ondelete="CASCADE"), nullable=False)
    is_primary = Column(Boolean, default=False, nullable=False)
    
    user = relationship("User", back_populates="site_assignments")
    site = relationship("Site", back_populates="user_assignments")
