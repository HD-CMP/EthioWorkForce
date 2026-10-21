from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime

from app.models.user import UserRole
from app.models.user_registration_request import RequestStatus


class RegistrationRequestCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=100)
    email: Optional[EmailStr] = None
    full_name: str = Field(..., min_length=1, max_length=255)
    phone_number: Optional[str] = None
    password: str
    role: UserRole = UserRole.VIEWER
    preferred_language: str = "en"
    request_reason: Optional[str] = None
    site_ids: Optional[list[int]] = None
    work_place_ids: Optional[list[int]] = None
    worker_id: Optional[int] = None
    
    @field_validator('email', mode='before')
    @classmethod
    def empty_str_to_none(cls, v):
        if v == '':
            return None
        return v
    
    @field_validator('password')
    @classmethod
    def handle_empty_password(cls, v):
        if v == '' or v is None:
            from datetime import datetime
            return f'KEEP_EXISTING_PASSWORD_{datetime.now().timestamp()}'
        if not v.startswith('KEEP_EXISTING_PASSWORD_') and len(v) < 6:
            raise ValueError('Password must be at least 6 characters')
        return v


class RegistrationRequestResponse(BaseModel):
    id: int
    username: str
    email: Optional[str] = None
    full_name: str
    phone_number: Optional[str]
    role: UserRole
    preferred_language: str
    requested_by_id: int
    approved_by_id: Optional[int]
    status: RequestStatus
    request_reason: Optional[str]
    approval_notes: Optional[str]
    created_at: datetime
    reviewed_at: Optional[datetime]
    site_ids: Optional[list[int]] = None
    site_names: Optional[list[str]] = None
    worker_id: Optional[int] = None

    class Config:
        from_attributes = True


class RegistrationApprovalAction(BaseModel):
    request_id: int
    approved: bool
    approval_notes: Optional[str] = None
    site_ids: Optional[list[int]] = Field(default=None, description="Sites to assign user to (for SITE_ADMIN, SUPERVISOR)")
    work_place_ids: Optional[list[int]] = Field(default=None, description="Work places to assign user to")
    worker_id: Optional[int] = Field(default=None, description="Linked worker ID")


class UserSiteAssignmentCreate(BaseModel):
    site_id: int
    is_primary: bool = False


class UserSiteAssignmentResponse(BaseModel):
    id: int
    user_id: int
    site_id: int
    is_primary: bool
    created_at: datetime

    class Config:
        from_attributes = True
