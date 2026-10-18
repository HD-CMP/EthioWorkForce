from typing import Generator, Optional, List
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session, joinedload

from app.core.database import get_db
from app.core.security import decode_token
from app.models.user import User, UserRole
from app.models.user_site_assignment import UserSiteAssignment
from app.models.user_work_place_assignment import UserWorkPlaceAssignment

security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    token = credentials.credentials
    payload = decode_token(token)
    
    user_id = payload.get("user_id")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    user = db.query(User).options(
        joinedload(User.work_place_assignments).joinedload(UserWorkPlaceAssignment.work_place)
    ).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user"
        )
    
    return user


def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


def require_role(allowed_roles: list[UserRole]):
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions"
            )
        return current_user
    return role_checker


def get_user_accessible_sites(user: User, db: Session) -> Optional[List[int]]:
    if user.role in [UserRole.SUPER_ADMIN, UserRole.ADMIN]:
        return None
    
    site_assignments = db.query(UserSiteAssignment).filter(
        UserSiteAssignment.user_id == user.id
    ).all()
    
    return [assignment.site_id for assignment in site_assignments]


def verify_site_access(user: User, site_id: int, db: Session) -> bool:
    if user.role in [UserRole.SUPER_ADMIN, UserRole.ADMIN]:
        return True
    
    assignment = db.query(UserSiteAssignment).filter(
        UserSiteAssignment.user_id == user.id,
        UserSiteAssignment.site_id == site_id
    ).first()
    
    return assignment is not None


def require_site_access(site_id: int):
    def site_checker(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> User:
        if not verify_site_access(current_user, site_id, db):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this site"
            )
        return current_user
    return site_checker


def can_manage_users(current_user: User) -> bool:
    return current_user.role in [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SITE_ADMIN]


def can_approve_users(current_user: User) -> bool:
    return current_user.role == UserRole.SUPER_ADMIN


def require_user_management():
    def checker(current_user: User = Depends(get_current_user)) -> User:
        if not can_manage_users(current_user):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only SUPER_ADMIN, ADMIN, and SITE_ADMIN can manage users"
            )
        return current_user
    return checker


def require_super_admin():
    def checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role != UserRole.SUPER_ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only SUPER_ADMIN can perform this action"
            )
        return current_user
    return checker
