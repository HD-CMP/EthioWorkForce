from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class WorkPlaceBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    code: str = Field(..., min_length=1, max_length=50)
    description: Optional[str] = None
    location_address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    parent_site_id: int = Field(..., description="Parent site ID")
    supervisor_id: Optional[int] = Field(default=None, description="Optional supervisor for this work place")


class WorkPlaceCreate(WorkPlaceBase):
    pass


class WorkPlaceUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    description: Optional[str] = None
    location_address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    supervisor_id: Optional[int] = None
    is_active: Optional[bool] = None


class WorkPlaceResponse(WorkPlaceBase):
    id: int
    is_active: bool
    supervisor_name: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
