from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional

from app.core.database import get_db
from app.api.deps import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.work_place import WorkPlace
from app.models.site import Site
from app.models.worker import Worker
from app.schemas.work_place import WorkPlaceCreate, WorkPlaceUpdate, WorkPlaceResponse

router = APIRouter()


def enrich_work_place_response(work_place: WorkPlace) -> dict:
    work_place_dict = {
        "id": work_place.id,
        "name": work_place.name,
        "code": work_place.code,
        "description": work_place.description,
        "location_address": work_place.location_address,
        "latitude": work_place.latitude,
        "longitude": work_place.longitude,
        "parent_site_id": work_place.parent_site_id,
        "supervisor_id": work_place.supervisor_id,
        "supervisor_name": work_place.supervisor.full_name if work_place.supervisor else None,
        "is_active": work_place.is_active,
        "created_at": work_place.created_at,
        "updated_at": work_place.updated_at,
    }
    return work_place_dict


@router.post("/", response_model=WorkPlaceResponse, status_code=status.HTTP_201_CREATED)
def create_work_place(
    work_place_data: WorkPlaceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    # Verify parent site exists
    site = db.query(Site).filter(Site.id == work_place_data.parent_site_id).first()
    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Parent site not found"
        )
    
    # Check for duplicate code within the same site
    existing = db.query(WorkPlace).filter(
        WorkPlace.parent_site_id == work_place_data.parent_site_id,
        WorkPlace.code == work_place_data.code
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Work place code already exists in this site"
        )
    
    db_work_place = WorkPlace(**work_place_data.model_dump())
    db.add(db_work_place)
    db.commit()
    db.refresh(db_work_place)
    
    db_work_place = db.query(WorkPlace).options(joinedload(WorkPlace.supervisor)).filter(WorkPlace.id == db_work_place.id).first()
    return enrich_work_place_response(db_work_place)


@router.get("/", response_model=List[WorkPlaceResponse])
def list_work_places(
    skip: int = 0,
    limit: int = 100,
    site_id: Optional[int] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(WorkPlace).options(joinedload(WorkPlace.supervisor))
    if site_id is not None:
        query = query.filter(WorkPlace.parent_site_id == site_id)
    if is_active is not None:
        query = query.filter(WorkPlace.is_active == is_active)
    work_places = query.offset(skip).limit(limit).all()
    return [enrich_work_place_response(wp) for wp in work_places]


@router.get("/{work_place_id}", response_model=WorkPlaceResponse)
def get_work_place(
    work_place_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    work_place = db.query(WorkPlace).options(joinedload(WorkPlace.supervisor)).filter(WorkPlace.id == work_place_id).first()
    if not work_place:
        raise HTTPException(status_code=404, detail="Work place not found")
    return enrich_work_place_response(work_place)


@router.patch("/{work_place_id}", response_model=WorkPlaceResponse)
def update_work_place(
    work_place_id: int,
    work_place_update: WorkPlaceUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    work_place = db.query(WorkPlace).filter(WorkPlace.id == work_place_id).first()
    if not work_place:
        raise HTTPException(status_code=404, detail="Work place not found")
    
    update_data = work_place_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(work_place, field, value)
    
    db.commit()
    db.refresh(work_place)
    
    work_place = db.query(WorkPlace).options(joinedload(WorkPlace.supervisor)).filter(WorkPlace.id == work_place_id).first()
    return enrich_work_place_response(work_place)


@router.delete("/{work_place_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_work_place(
    work_place_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    work_place = db.query(WorkPlace).filter(WorkPlace.id == work_place_id).first()
    if not work_place:
        raise HTTPException(status_code=404, detail="Work place not found")
    
    db.delete(work_place)
    db.commit()
    return None
