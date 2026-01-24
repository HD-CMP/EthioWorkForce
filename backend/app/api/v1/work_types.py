from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.deps import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.work_type import WorkType
from app.schemas.work_type import WorkTypeCreate, WorkTypeUpdate, WorkTypeResponse

router = APIRouter()


@router.post("/", response_model=WorkTypeResponse, status_code=status.HTTP_201_CREATED)
def create_work_type(
    work_type_data: WorkTypeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.HR_OFFICER]))
):
    existing = db.query(WorkType).filter(WorkType.code == work_type_data.code).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Work type code already exists"
        )
    
    db_work_type = WorkType(**work_type_data.model_dump())
    db.add(db_work_type)
    db.commit()
    db.refresh(db_work_type)
    return db_work_type


@router.get("/", response_model=List[WorkTypeResponse])
def list_work_types(
    skip: int = 0,
    limit: int = 100,
    is_active: bool = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(WorkType)
    if is_active is not None:
        query = query.filter(WorkType.is_active == is_active)
    work_types = query.offset(skip).limit(limit).all()
    return work_types


@router.get("/{work_type_id}", response_model=WorkTypeResponse)
def get_work_type(
    work_type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    work_type = db.query(WorkType).filter(WorkType.id == work_type_id).first()
    if not work_type:
        raise HTTPException(status_code=404, detail="Work type not found")
    return work_type


@router.patch("/{work_type_id}", response_model=WorkTypeResponse)
def update_work_type(
    work_type_id: int,
    work_type_update: WorkTypeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.HR_OFFICER]))
):
    work_type = db.query(WorkType).filter(WorkType.id == work_type_id).first()
    if not work_type:
        raise HTTPException(status_code=404, detail="Work type not found")
    
    update_data = work_type_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(work_type, field, value)
    
    db.commit()
    db.refresh(work_type)
    return work_type


@router.delete("/{work_type_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_work_type(
    work_type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    work_type = db.query(WorkType).filter(WorkType.id == work_type_id).first()
    if not work_type:
        raise HTTPException(status_code=404, detail="Work type not found")
    
    db.delete(work_type)
    db.commit()
    return None
