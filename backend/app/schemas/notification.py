from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime


class NotificationBase(BaseModel):
    type: str
    title: str
    message: str
    extra_data: Optional[Dict[str, Any]] = Field(None, alias="metadata")


class NotificationCreate(NotificationBase):
    user_id: int


class NotificationResponse(NotificationBase):
    id: int
    user_id: int
    is_read: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
        populate_by_name = True


class NotificationMarkRead(BaseModel):
    notification_ids: list[int]
