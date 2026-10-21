from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone

from app.core.database import get_db
from app.api.deps import get_current_user, require_user_management, require_super_admin, can_approve_users
from app.core.security import get_password_hash
from app.models.user import User, UserRole
from app.models.user_registration_request import UserRegistrationRequest, RequestStatus
from app.models.user_site_assignment import UserSiteAssignment
from app.models.user_work_place_assignment import UserWorkPlaceAssignment
from app.models.site import Site
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
    keep_existing_password = request_data.password.startswith("KEEP_EXISTING_PASSWORD_")
    
    # Check for existing username
    existing_user = db.query(User).filter(User.username == request_data.username).first()
    is_upgrade_request = existing_user is not None
    
    if not is_upgrade_request and keep_existing_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error_code": "PASSWORD_REQUIRED",
                "message": f"Password is required for new user registration",
                "username": request_data.username
            }
        )
    
    # Check for existing email only if email is provided and it's a new registration
    if request_data.email and not is_upgrade_request:
        existing_email = db.query(User).filter(User.email == request_data.email).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error_code": "EMAIL_EXISTS",
                    "message": "Email already exists",
                    "email": request_data.email
                }
            )
    
    # Check for pending requests
    pending_filters = [UserRegistrationRequest.username == request_data.username]
    if request_data.email:
        pending_filters.append(UserRegistrationRequest.email == request_data.email)
    
    existing_request = db.query(UserRegistrationRequest).filter(
        *pending_filters,
        UserRegistrationRequest.status == RequestStatus.PENDING
    ).first()
    
    if existing_request:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error_code": "DUPLICATE_REQUEST",
                "message": "A pending registration request already exists for this username or email",
                "request_id": existing_request.id,
                "username": existing_request.username,
                "created_at": existing_request.created_at.isoformat() if existing_request.created_at else None
            }
        )
    
    if current_user.role == UserRole.SITE_ADMIN and request_data.role in [UserRole.SUPER_ADMIN, UserRole.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error_code": "PERMISSION_DENIED",
                "message": "SITE_ADMIN cannot request SUPER_ADMIN or ADMIN roles",
                "current_role": current_user.role.value,
                "requested_role": request_data.role.value
            }
        )
    
    if current_user.role == UserRole.ADMIN and request_data.role == UserRole.SUPER_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error_code": "PERMISSION_DENIED",
                "message": "ADMIN cannot request SUPER_ADMIN role",
                "current_role": current_user.role.value,
                "requested_role": request_data.role.value
            }
        )
    
    hashed_password = request_data.password if keep_existing_password else get_password_hash(request_data.password)
    
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
        site_ids=request_data.site_ids,
        work_place_ids=request_data.work_place_ids,
        worker_id=request_data.worker_id,
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
    
    # Enrich requests with site names
    for request in requests:
        if request.site_ids and len(request.site_ids) > 0:
            sites = db.query(Site).filter(Site.id.in_(request.site_ids)).all()
            request.site_names = [site.name for site in sites]
        else:
            request.site_names = []
    
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
    
    # Enrich requests with site names
    for request in requests:
        if request.site_ids and len(request.site_ids) > 0:
            sites = db.query(Site).filter(Site.id.in_(request.site_ids)).all()
            request.site_names = [site.name for site in sites]
        else:
            request.site_names = []
    
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
        existing_user = db.query(User).filter(User.username == request.username).first()
        
        if existing_user:
            # This is an upgrade request - update existing user
            existing_user.role = UserRole(request.role)
            existing_user.full_name = request.full_name
            if request.email:
                existing_user.email = request.email
            if request.phone_number:
                existing_user.phone_number = request.phone_number
            existing_user.preferred_language = request.preferred_language
            if request.worker_id:
                existing_user.worker_id = request.worker_id
            elif approval_data.worker_id:
                existing_user.worker_id = approval_data.worker_id
            # Update password if it was changed (not the placeholder)
            if not request.hashed_password.startswith('KEEP_EXISTING_PASSWORD_'):
                existing_user.hashed_password = request.hashed_password
            
            # Clear existing assignments
            db.query(UserSiteAssignment).filter(
                UserSiteAssignment.user_id == existing_user.id
            ).delete()
            db.query(UserWorkPlaceAssignment).filter(
                UserWorkPlaceAssignment.user_id == existing_user.id
            ).delete()
            
            # Add new assignments (use approval_data if provided, otherwise use request data)
            final_site_ids = approval_data.site_ids if approval_data.site_ids else request.site_ids
            final_work_place_ids = approval_data.work_place_ids if approval_data.work_place_ids else request.work_place_ids
            
            if final_site_ids and len(final_site_ids) > 0:
                for idx, site_id in enumerate(final_site_ids):
                    site_assignment = UserSiteAssignment(
                        user_id=existing_user.id,
                        site_id=site_id,
                        is_primary=(idx == 0)
                    )
                    db.add(site_assignment)
            
            if final_work_place_ids and len(final_work_place_ids) > 0:
                for idx, work_place_id in enumerate(final_work_place_ids):
                    work_place_assignment = UserWorkPlaceAssignment(
                        user_id=existing_user.id,
                        work_place_id=work_place_id,
                        is_primary=(idx == 0)
                    )
                    db.add(work_place_assignment)
            
            request.status = RequestStatus.APPROVED
            request.approval_notes = approval_data.approval_notes or "User upgraded successfully"
            request.reviewed_at = datetime.now(timezone.utc)
            request.approved_by_id = current_user.id
            
            db.commit()
            db.refresh(existing_user)
            
            return {
                "message": "User upgraded successfully",
                "user_id": existing_user.id,
                "username": existing_user.username
            }
        else:
            # This is a new user registration
            new_user = User(
                username=request.username,
                email=request.email,
                full_name=request.full_name,
                phone_number=request.phone_number,
                hashed_password=request.hashed_password,
                role=UserRole(request.role),
                preferred_language=request.preferred_language,
                worker_id=approval_data.worker_id or request.worker_id,
                is_active=True,
                is_verified=True
            )
            
            db.add(new_user)
            db.flush()
            
            # Use approval_data if provided, otherwise use request data
            final_site_ids = approval_data.site_ids if approval_data.site_ids else request.site_ids
            final_work_place_ids = approval_data.work_place_ids if approval_data.work_place_ids else request.work_place_ids
            
            if final_site_ids and len(final_site_ids) > 0:
                for idx, site_id in enumerate(final_site_ids):
                    site_assignment = UserSiteAssignment(
                        user_id=new_user.id,
                        site_id=site_id,
                        is_primary=(idx == 0)
                    )
                    db.add(site_assignment)
            
            if final_work_place_ids and len(final_work_place_ids) > 0:
                for idx, work_place_id in enumerate(final_work_place_ids):
                    work_place_assignment = UserWorkPlaceAssignment(
                        user_id=new_user.id,
                        work_place_id=work_place_id,
                        is_primary=(idx == 0)
                    )
                    db.add(work_place_assignment)
            
            request.status = RequestStatus.APPROVED
            request.approval_notes = approval_data.approval_notes
            request.reviewed_at = datetime.now(timezone.utc)
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
        request.reviewed_at = datetime.now(timezone.utc)
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
    request.reviewed_at = datetime.now(timezone.utc)
    
    db.commit()
    return None
