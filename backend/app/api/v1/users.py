from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid
import base64

from app.core.database import get_db
from app.api.deps import get_current_user, require_role, require_super_admin, can_manage_users
from app.models.user import User, UserRole
from app.models.user_site_assignment import UserSiteAssignment
from app.models.user_work_place_assignment import UserWorkPlaceAssignment
from app.models.work_place import WorkPlace
from app.models.worker import Worker, WorkerStatus
from app.schemas.user import UserResponse, UserUpdate, UserProfileUpdate
from app.schemas.registration_request import UserSiteAssignmentCreate, UserSiteAssignmentResponse
from app.core.security import get_password_hash
from pydantic import BaseModel

router = APIRouter()


def _save_avatar_bytes(content: bytes, extension: str = ".jpg") -> str:
    upload_dir = os.path.join("uploads", "avatars")
    os.makedirs(upload_dir, exist_ok=True)
    filename = f"avatar_{uuid.uuid4().hex}{extension}"
    filepath = os.path.join(upload_dir, filename)
    with open(filepath, "wb") as f:
        f.write(content)
    return f"/uploads/avatars/{filename}"


def _process_avatar_data(data_str: Optional[str]) -> Optional[str]:
    if not data_str:
        return None
    if data_str.startswith("/") or data_str.startswith("http://") or data_str.startswith("https://"):
        return data_str
    if "base64," in data_str:
        header, b64_content = data_str.split("base64,", 1)
        ext = ".png" if "image/png" in header else ".jpg"
        try:
            raw_bytes = base64.b64decode(b64_content)
            return _save_avatar_bytes(raw_bytes, ext)
        except Exception:
            return data_str
    elif len(data_str) > 200:
        try:
            raw_bytes = base64.b64decode(data_str)
            return _save_avatar_bytes(raw_bytes, ".jpg")
        except Exception:
            return data_str
    return data_str


@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user


@router.post("/me/avatar", response_model=UserResponse)
async def upload_my_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload and set avatar for the current logged-in user permanently."""
    ext = os.path.splitext(file.filename or "")[1].lower()
    if not ext or ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        ext = ".jpg"
    
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")
    
    file_url = _save_avatar_bytes(content, ext)
    current_user.profile_photo = file_url
    db.commit()
    db.refresh(current_user)
    return current_user


@router.delete("/me/avatar", response_model=UserResponse)
def remove_my_avatar(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Remove avatar for the current logged-in user permanently."""
    current_user.profile_photo = None
    db.commit()
    db.refresh(current_user)
    return current_user


@router.patch("/me/profile", response_model=UserResponse)
def update_my_profile(
    profile_update: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    update_data = profile_update.model_dump(exclude_unset=True)
    
    if 'username' in update_data:
        existing_user = db.query(User).filter(
            User.username == update_data['username'],
            User.id != current_user.id
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
    
    if 'email' in update_data:
        existing_user = db.query(User).filter(
            User.email == update_data['email'],
            User.id != current_user.id
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already in use"
            )
    
    if 'profile_photo' in update_data:
        if update_data['profile_photo']:
            update_data['profile_photo'] = _process_avatar_data(update_data['profile_photo'])
        else:
            update_data['profile_photo'] = None

    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    return current_user


@router.get("/search")
def search_workers(
    q: str,
    site_id: int = None,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    search_term = f"%{q}%"
    query = db.query(Worker).filter(
        (Worker.full_name.ilike(search_term)) |
        (Worker.employee_id.ilike(search_term)) |
        (Worker.phone_number.ilike(search_term))
    )
    
    # Filter by site if provided
    if site_id is not None:
        query = query.filter(Worker.site_id == site_id)
    
    # Only return active workers
    query = query.filter(Worker.status == WorkerStatus.ACTIVE)
    
    workers = query.limit(limit).all()
    
    # Convert workers to UserResponse format for frontend compatibility
    return [{
        "id": w.id,
        "worker_id": w.id,
        "employee_id": w.employee_id,
        "username": w.employee_id,
        "email": "",
        "full_name": w.full_name,
        "phone_number": w.phone_number or "",
        "role": w.work_type.name if w.work_type else "Worker",
        "work_type_id": w.work_type_id,
        "work_type_name": w.work_type.name if w.work_type else "Worker",
        "hierarchy_level": w.work_type.hierarchy_level if w.work_type else 5,
        "is_active": w.status == WorkerStatus.ACTIVE,
        "site_id": w.site_id,
        "work_place_id": w.work_place_id,
        "has_user_account": w.user_account is not None
    } for w in workers]


@router.get("/check-username")
def check_username_availability(
    username: str,
    db: Session = Depends(get_db)
):
    """Check if a username is available"""
    existing_user = db.query(User).filter(User.username == username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already exists"
        )
    return {"available": True, "username": username}


@router.get("/", response_model=List[UserResponse])
def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    # Super admins can see all users
    if current_user.role == UserRole.SUPER_ADMIN:
        users = db.query(User).offset(skip).limit(limit).all()
        return users
    
    # Regular admins need both site AND workplace assignments to see users
    admin_site_ids = [assignment.site_id for assignment in current_user.site_assignments]
    admin_workplace_ids = [wp.work_place_id for wp in current_user.work_place_assignments]
    
    # If admin has no site assignments OR no workplace assignments, show nothing
    if not admin_site_ids or not admin_workplace_ids:
        return []
    
    # Get users who have assignments to the admin's sites
    users = db.query(User).join(UserSiteAssignment).filter(
        UserSiteAssignment.site_id.in_(admin_site_ids)
    ).distinct().offset(skip).limit(limit).all()
    
    return users


@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.patch("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not can_manage_users(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions to update users"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if current_user.role == UserRole.SITE_ADMIN and user.role in [UserRole.SUPER_ADMIN, UserRole.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="SITE_ADMIN cannot update SUPER_ADMIN or ADMIN users"
        )
    
    update_data = user_update.model_dump(exclude_unset=True)
    
    if 'role' in update_data:
        if current_user.role == UserRole.SITE_ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="SITE_ADMIN cannot change user roles"
            )
        if current_user.role == UserRole.ADMIN and update_data['role'] == UserRole.SUPER_ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="ADMIN cannot assign SUPER_ADMIN role"
            )
    
    if 'profile_photo' in update_data:
        if update_data['profile_photo']:
            update_data['profile_photo'] = _process_avatar_data(update_data['profile_photo'])
        else:
            update_data['profile_photo'] = None

    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN]))
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    return None


class PasswordResetRequest(BaseModel):
    new_password: str

@router.post("/{user_id}/reset-password", status_code=status.HTTP_200_OK)
def reset_user_password(
    user_id: int,
    password_data: PasswordResetRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    if not can_manage_users(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions to reset passwords"
        )
        
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if current_user.role == UserRole.ADMIN and user.role == UserRole.SUPER_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ADMIN cannot reset SUPER_ADMIN password"
        )
        
    if len(password_data.new_password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters")
        
    user.hashed_password = get_password_hash(password_data.new_password)
    db.commit()
    
    return {"message": "Password reset successfully"}


@router.get("/{user_id}/sites", response_model=List[UserSiteAssignmentResponse])
def get_user_site_assignments(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.id != user_id and not can_manage_users(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own site assignments"
        )
    
    assignments = db.query(UserSiteAssignment).filter(
        UserSiteAssignment.user_id == user_id
    ).all()
    
    return assignments


@router.post("/{user_id}/sites", response_model=UserSiteAssignmentResponse, status_code=status.HTTP_201_CREATED)
def assign_user_to_site(
    user_id: int,
    assignment_data: UserSiteAssignmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    existing = db.query(UserSiteAssignment).filter(
        UserSiteAssignment.user_id == user_id,
        UserSiteAssignment.site_id == assignment_data.site_id
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already assigned to this site"
        )
    
    if assignment_data.is_primary:
        db.query(UserSiteAssignment).filter(
            UserSiteAssignment.user_id == user_id
        ).update({"is_primary": False})
    
    db_assignment = UserSiteAssignment(
        user_id=user_id,
        site_id=assignment_data.site_id,
        is_primary=assignment_data.is_primary
    )
    
    db.add(db_assignment)
    db.commit()
    db.refresh(db_assignment)
    
    return db_assignment


@router.delete("/{user_id}/sites/{site_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_user_site_assignment(
    user_id: int,
    site_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    assignment = db.query(UserSiteAssignment).filter(
        UserSiteAssignment.user_id == user_id,
        UserSiteAssignment.site_id == site_id
    ).first()
    
    if not assignment:
        raise HTTPException(status_code=404, detail="Site assignment not found")
    
    db.delete(assignment)
    db.commit()
    return None


from pydantic import BaseModel as PydanticBaseModel

class WorkplaceAssignmentUpdate(PydanticBaseModel):
    workplace_ids: List[int]


@router.post("/{user_id}/workplace-assignments", status_code=status.HTTP_200_OK)
def update_user_workplace_assignments(
    user_id: int,
    data: WorkplaceAssignmentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]))
):
    """Update user's workplace assignments"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify all workplaces exist
    for wp_id in data.workplace_ids:
        workplace = db.query(WorkPlace).filter(WorkPlace.id == wp_id).first()
        if not workplace:
            raise HTTPException(status_code=404, detail=f"Workplace {wp_id} not found")
    
    # Remove existing assignments
    db.query(UserWorkPlaceAssignment).filter(
        UserWorkPlaceAssignment.user_id == user_id
    ).delete()
    
    # Add new assignments
    for idx, wp_id in enumerate(data.workplace_ids):
        assignment = UserWorkPlaceAssignment(
            user_id=user_id,
            work_place_id=wp_id,
            is_primary=(idx == 0)  # First one is primary
        )
        db.add(assignment)
    
    db.commit()
    
    return {"message": "Workplace assignments updated successfully", "workplace_ids": data.workplace_ids}


@router.patch("/{user_id}/profile", response_model=UserResponse)
def update_user_profile(
    user_id: int,
    profile_update: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    """Update user profile by admin"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    update_data = profile_update.model_dump(exclude_unset=True)
    
    if 'email' in update_data:
        existing_user = db.query(User).filter(
            User.email == update_data['email'],
            User.id != user_id
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already in use"
            )
    
    if 'profile_photo' in update_data:
        if update_data['profile_photo']:
            update_data['profile_photo'] = _process_avatar_data(update_data['profile_photo'])
        else:
            update_data['profile_photo'] = None

    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    
    return user
