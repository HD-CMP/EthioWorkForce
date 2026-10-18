from sqlalchemy import Column, Integer, String, Boolean, Float, ForeignKey
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class WorkPlace(BaseModel):
    __tablename__ = "work_places"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    code = Column(String(50), nullable=False, index=True)
    description = Column(String(1000), nullable=True)
    location_address = Column(String(500), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    parent_site_id = Column(Integer, ForeignKey("sites.id"), nullable=False)
    supervisor_id = Column(Integer, ForeignKey("workers.id"), nullable=True)
    
    is_active = Column(Boolean, default=True, nullable=False)
    
    site = relationship("Site", backref="work_places")
    supervisor = relationship("Worker", foreign_keys=[supervisor_id])
