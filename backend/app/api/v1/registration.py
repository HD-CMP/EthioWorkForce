from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.core.database import get_db
from app.api.deps import get_current_user, require_user_management, require_super_admin, can_approve_users
from app.core.security import get_password_hash
from app.models.user import User, UserRole
from app.models.user_registration_request import UserRegistrationRequest, RequestStatus
from app.models.user_site_assignment import UserSiteAssignment
from app.schemas.registration_request import (
    RegistrationRequestCreate,
    RegistrationRequestResponse,
    RegistrationApprovalAction
)

router = APIRouter()


@router.post("/request", response_model=RegistrationRequestResponse, status_code=status.HTTP_201_CREATED)
def request_user_registration(
    request_data: RegistrationRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user_management())
):
    existing_user = db.query(User).filter(
        (User.username == request_data.username) | (User.email == request_data.email)
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already exists"
        )
    
    existing_request = db.query(UserRegistrationRequest).filter(
        (UserRegistrationRequest.username == request_data.username) | 
        (UserRegistrationRequest.email == request_data.email),
        UserRegistrationRequest.status == RequestStatus.PENDING
    ).first()
    
    if existing_request:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A pending registration request already exists for this username or email"
        )
    
    if current_user.role == UserRole.SITE_ADMIN and request_data.role in [UserRole.SUPER_ADMIN, UserRole.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="SITE_ADMIN cannot request SUPER_ADMIN or ADMIN roles"
        )
    
    if current_user.role == UserRole.ADMIN and request_data.role == UserRole.SUPER_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ADMIN cannot request SUPER_ADMIN role"
        )
    
    hashed_password = get_password_hash(request_data.password)
    
    db_request = UserRegistrationRequest(
        username=request_data.username,
        email=request_data.email,
        full_name=request_data.full_name,
        phone_number=request_data.phone_number,
        role=request_data.role.value,
        preferred_language=request_data.preferred_language,
        hashed_password=hashed_password,
        requested_by_id=current_user.id,
        request_reason=request_data.request_reason,
        status=RequestStatus.PENDING
    )
    
    db.add(db_request)
    db.commit()
    db.refresh(db_request)
    
    return db_request


@router.get("/requests", response_model=List[RegistrationRequestResponse])
def list_registration_requests(
    status_filter: RequestStatus = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(UserRegistrationRequest)
    
    if current_user.role != UserRole.SUPER_ADMIN:
        query = query.filter(UserRegistrationRequest.requested_by_id == current_user.id)
    
    if status_filter:
        query = query.filter(UserRegistrationRequest.status == status_filter)
    
    requests = query.order_by(UserRegistrationRequest.created_at.desc()).offset(skip).limit(limit).all()
    return requests


@router.get("/requests/pending", response_model=List[RegistrationRequestResponse])
def list_pending_requests(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin())
):
    requests = db.query(UserRegistrationRequest).filter(
        UserRegistrationRequest.status == RequestStatus.PENDING
    ).order_by(UserRegistrationRequest.created_at.asc()).offset(skip).limit(limit).all()
    
    return requests


@router.post("/approve", response_model=dict)
def approve_registration_request(
    approval_data: RegistrationApprovalAction,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_super_admin())
):
    request = db.query(UserRegistrationRequest).filter(
        UserRegistrationRequest.id == approval_data.request_id
    ).first()
    
    if not request:
        raise HTTPException(status_code=404, detail="Registration request not found")
    
    if request.status != RequestStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only pending requests can be approved or rejected"
        )
    
    if approval_data.approved:
        existing_user = db.query(User).filter(
            (User.username == request.username) | (User.email == request.email)
        ).first()
        
        if existing_user:
            request.status = RequestStatus.REJECTED
            request.approval_notes = "Username or email already exists"
            request.reviewed_at = datetime.utcnow()
            request.approved_by_id = current_user.id
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username or email already exists"
            )
        
        new_user = User(
            username=request.username,
            email=request.email,
            full_name=request.full_name,
            phone_number=request.phone_number,
            hashed_password=request.hashed_password,
            role=UserRole(request.role),
            preferred_language=request.preferred_language,
            is_active=True,
            is_verified=True
        )
        
        db.add(new_user)
        db.flush()
        
        if approval_data.site_ids and len(approval_data.site_ids) > 0:
            for idx, site_id in enumerate(approval_data.site_ids):
                site_assignment = UserSiteAssignment(
                    user_id=new_user.id,
                    site_id=site_id,
                    is_primary=(idx == 0)
                )
                db.add(site_assignment)
        
        request.status = RequestStatus.APPROVED
        request.approval_notes = approval_data.approval_notes
        request.reviewed_at = datetime.utcnow()
        request.approved_by_id = current_user.id
        
        db.commit()
        db.refresh(new_user)
        
        return {
            "message": "Registration request approved successfully",
            "user_id": new_user.id,
            "username": new_user.username
        }
    else:
        request.status = RequestStatus.REJECTED
        request.approval_notes = approval_data.approval_notes or "Rejected by administrator"
        request.reviewed_at = datetime.utcnow()
        request.approved_by_id = current_user.id
        
        db.commit()
        
        return {
            "message": "Registration request rejected",
            "request_id": request.id
        }


@router.delete("/requests/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
def cancel_registration_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    request = db.query(UserRegistrationRequest).filter(
        UserRegistrationRequest.id == request_id
    ).first()
    
    if not request:
        raise HTTPException(status_code=404, detail="Registration request not found")
    
    if request.requested_by_id != current_user.id and current_user.role != UserRole.SUPER_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only cancel your own requests"
        )
    
    if request.status != RequestStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only pending requests can be cancelled"
        )
    
    request.status = RequestStatus.CANCELLED
    request.reviewed_at = datetime.utcnow()
    
    db.commit()
    return None
