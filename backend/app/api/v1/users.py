from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.deps import get_current_user, require_role, require_super_admin, can_manage_users
from app.models.user import User, UserRole
from app.models.user_site_assignment import UserSiteAssignment
from app.schemas.user import UserResponse, UserUpdate, UserProfileUpdate
from app.schemas.registration_request import UserSiteAssignmentCreate, UserSiteAssignmentResponse

router = APIRouter()


@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
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
    
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    return current_user


@router.get("/", response_model=List[UserResponse])
def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    users = db.query(User).offset(skip).limit(limit).all()
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
