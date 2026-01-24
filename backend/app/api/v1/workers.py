from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.deps import get_current_user, get_user_accessible_sites, verify_site_access
from app.models.user import User
from app.models.worker import Worker
from app.schemas.worker import WorkerCreate, WorkerUpdate, WorkerResponse
from app.services.qr_service import QRCodeService

router = APIRouter()
qr_service = QRCodeService()


@router.post("/", response_model=WorkerResponse, status_code=status.HTTP_201_CREATED)
def create_worker(
    worker_data: WorkerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, worker_data.site_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this site"
        )
    
    existing = db.query(Worker).filter(Worker.employee_id == worker_data.employee_id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Employee ID already exists"
        )
    
    db_worker = Worker(**worker_data.model_dump())
    db.add(db_worker)
    db.commit()
    db.refresh(db_worker)
    return db_worker


@router.get("/", response_model=List[WorkerResponse])
def list_workers(
    skip: int = 0,
    limit: int = 100,
    site_id: int = None,
    work_type_id: int = None,
    status: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Worker)
    
    accessible_sites = get_user_accessible_sites(current_user, db)
    if accessible_sites is not None:
        query = query.filter(Worker.site_id.in_(accessible_sites))
    
    if site_id:
        if accessible_sites is not None and site_id not in accessible_sites:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this site"
            )
        query = query.filter(Worker.site_id == site_id)
    
    if work_type_id:
        query = query.filter(Worker.work_type_id == work_type_id)
    if status:
        query = query.filter(Worker.status == status)
    
    workers = query.offset(skip).limit(limit).all()
    return workers


@router.get("/{worker_id}", response_model=WorkerResponse)
def get_worker(
    worker_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    return worker


@router.patch("/{worker_id}", response_model=WorkerResponse)
def update_worker(
    worker_id: int,
    worker_update: WorkerUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    update_data = worker_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(worker, field, value)
    
    db.commit()
    db.refresh(worker)
    return worker


@router.delete("/{worker_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_worker(
    worker_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    db.delete(worker)
    db.commit()
    return None


@router.post("/{worker_id}/generate-qr")
def generate_worker_qr(
    worker_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    qr_code = qr_service.generate_worker_qr(
        worker_id=worker.id,
        employee_id=worker.employee_id,
        full_name=worker.full_name,
        site_id=worker.site_id
    )
    
    worker.qr_code = qr_code
    db.commit()
    
    return {"qr_code": qr_code, "employee_id": worker.employee_id}
