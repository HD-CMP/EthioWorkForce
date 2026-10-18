from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.exc import IntegrityError
from typing import List, Optional

from app.core.database import get_db
from app.core.exceptions import (
    DuplicateEmployeeIDError,
    DuplicateNationalIDError,
    ResourceNotFoundError,
    UnauthorizedAccessError,
    DatabaseConstraintError
)
from app.api.deps import get_current_user, get_user_accessible_sites, verify_site_access, require_role
from app.models.user import User, UserRole
from app.models.worker import Worker
from app.models.site import Site
from app.models.work_place import WorkPlace
from app.models.work_type import WorkType
from app.schemas.worker import WorkerCreate, WorkerUpdate, WorkerResponse
from app.services.qr_service import QRCodeService

router = APIRouter()
qr_service = QRCodeService()


def enrich_worker_response(worker: Worker) -> dict:
    worker_dict = {
        "id": worker.id,
        "employee_id": worker.employee_id,
        "full_name": worker.full_name,
        "phone_number": worker.phone_number,
        "national_id": worker.national_id,
        "date_of_birth": worker.date_of_birth,
        "gender": worker.gender,
        "site_id": worker.site_id,
        "work_place_id": worker.work_place_id,
        "work_type_id": worker.work_type_id,
        "supervisor_id": worker.supervisor_id,
        "hire_date": worker.hire_date,
        "status": worker.status,
        "termination_date": worker.termination_date,
        "calendar_preference": worker.calendar_preference,
        "bank_name": worker.bank_name,
        "bank_account_number": worker.bank_account_number,
        "emergency_contact_name": worker.emergency_contact_name,
        "emergency_contact_phone": worker.emergency_contact_phone,
        "overtime_hours": worker.overtime_hours,
        "overtime_rate_per_hour": worker.overtime_rate_per_hour,
        "payment_period_days": worker.work_type.payment_period_days if worker.work_type else None,
        "base_salary": float(worker.base_salary) if worker.base_salary is not None else None,
        "photo_url": worker.photo_url,
        "qr_code": worker.qr_code,
        "created_at": worker.created_at,
        "updated_at": worker.updated_at,
        "site_name": worker.site.name if worker.site else None,
        "work_place_name": worker.work_place.name if worker.work_place else None,
        "work_place_supervisor_name": worker.work_place.supervisor.full_name if worker.work_place and worker.work_place.supervisor else None,
        "work_type": worker.work_type.name if worker.work_type else None,
        "hierarchy_level": worker.work_type.hierarchy_level if worker.work_type else None,
        "supervisor_name": worker.supervisor.full_name if worker.supervisor else None,
    }
    return worker_dict


@router.post("/", response_model=WorkerResponse, status_code=status.HTTP_201_CREATED)
def create_worker(
    worker_data: WorkerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, worker_data.site_id, db):
        raise UnauthorizedAccessError("site", "create workers in")
    
    site = db.query(Site).filter(Site.id == worker_data.site_id).first()
    work_type = db.query(WorkType).filter(WorkType.id == worker_data.work_type_id).first()
    
    if not site:
        raise ResourceNotFoundError("Site", worker_data.site_id)
    
    if not work_type:
        raise ResourceNotFoundError("Work Type", worker_data.work_type_id)
    
    if worker_data.work_place_id:
        work_place = db.query(WorkPlace).filter(WorkPlace.id == worker_data.work_place_id).first()
        if not work_place:
            raise ResourceNotFoundError("Work Place", worker_data.work_place_id)
        if work_place.parent_site_id != worker_data.site_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Work place '{work_place.name}' does not belong to site '{site.name}'"
            )
    
    existing = db.query(Worker).filter(
        Worker.employee_id == worker_data.employee_id,
        Worker.site_id == worker_data.site_id,
        Worker.work_type_id == worker_data.work_type_id
    ).first()
    
    if existing:
        raise DuplicateEmployeeIDError(
            employee_id=worker_data.employee_id,
            site_name=site.name,
            site_code=site.code,
            work_type_name=work_type.name,
            work_type_code=work_type.code,
            existing_worker={
                "id": existing.id,
                "name": existing.full_name
            }
        )
    
    db_worker = Worker(**worker_data.model_dump())
    db.add(db_worker)
    
    try:
        db.commit()
        db.refresh(db_worker)
    except IntegrityError as e:
        db.rollback()
        if "uq_worker_employee_id_site_work_type" in str(e.orig):
            raise DuplicateEmployeeIDError(
                employee_id=worker_data.employee_id,
                site_name=site.name,
                site_code=site.code,
                work_type_name=work_type.name,
                work_type_code=work_type.code
            )
        elif "national_id" in str(e.orig):
            raise DuplicateNationalIDError(worker_data.national_id or "Unknown")
        else:
            raise DatabaseConstraintError(
                constraint_name="unknown",
                message="Unable to create worker due to data conflict. Please verify all input data."
            )
    
    worker_with_relations = db.query(Worker).options(
        joinedload(Worker.site),
        joinedload(Worker.work_place).joinedload(WorkPlace.supervisor),
        joinedload(Worker.work_type),
        joinedload(Worker.supervisor)
    ).filter(Worker.id == db_worker.id).first()
    
    return enrich_worker_response(worker_with_relations)


@router.get("/check-employee-id", response_model=dict)
def check_employee_id_availability(
    employee_id: str,
    site_id: int,
    work_type_id: int,
    exclude_worker_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_site_access(current_user, site_id, db):
        raise UnauthorizedAccessError("site", "access")
    
    query = db.query(Worker).filter(
        Worker.employee_id == employee_id,
        Worker.site_id == site_id,
        Worker.work_type_id == work_type_id
    )
    
    if exclude_worker_id:
        query = query.filter(Worker.id != exclude_worker_id)
    
    existing = query.first()
    
    if existing:
        site = db.query(Site).filter(Site.id == site_id).first()
        work_type = db.query(WorkType).filter(WorkType.id == work_type_id).first()
        
        return {
            "available": False,
            "message": f"Employee ID '{employee_id}' is already assigned to {existing.full_name} at this site for this work type",
            "existing_worker": {
                "id": existing.id,
                "name": existing.full_name,
                "employee_id": existing.employee_id
            },
            "site_name": site.name if site else None,
            "work_type_name": work_type.name if work_type else None
        }
    
    return {
        "available": True,
        "message": f"Employee ID '{employee_id}' is available"
    }


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
    query = db.query(Worker).options(
        joinedload(Worker.site),
        joinedload(Worker.work_place).joinedload(WorkPlace.supervisor),
        joinedload(Worker.work_type),
        joinedload(Worker.supervisor)
    )
    
    # Filter by accessible sites
    accessible_sites = get_user_accessible_sites(current_user, db)
    if accessible_sites is not None:
        query = query.filter(Worker.site_id.in_(accessible_sites))
    
    # Strict workplace filtering for admins
    if current_user.role in [UserRole.ADMIN, UserRole.SITE_ADMIN]:
        workplace_assignments = current_user.work_place_assignments
        if workplace_assignments:
            # Admin has workplace assignments - show only those workplaces
            accessible_workplace_ids = [wp.work_place_id for wp in workplace_assignments]
            query = query.filter(Worker.work_place_id.in_(accessible_workplace_ids))
        else:
            # Admin has NO workplace assignments - show nothing
            query = query.filter(Worker.id == -1)  # Impossible condition, returns empty
    
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
    return [enrich_worker_response(w) for w in workers]


@router.get("/{worker_id}", response_model=WorkerResponse)
def get_worker(
    worker_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    worker = db.query(Worker).options(
        joinedload(Worker.site),
        joinedload(Worker.work_place).joinedload(WorkPlace.supervisor),
        joinedload(Worker.work_type),
        joinedload(Worker.supervisor)
    ).filter(Worker.id == worker_id).first()
    if not worker:
        raise ResourceNotFoundError("Worker", worker_id)
    return enrich_worker_response(worker)


@router.patch("/{worker_id}", response_model=WorkerResponse)
def update_worker(
    worker_id: int,
    worker_update: WorkerUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise ResourceNotFoundError("Worker", worker_id)
    
    update_data = worker_update.model_dump(exclude_unset=True)
    
    new_employee_id = update_data.get('employee_id', worker.employee_id)
    new_site_id = update_data.get('site_id', worker.site_id)
    new_work_place_id = update_data.get('work_place_id', worker.work_place_id)
    new_work_type_id = update_data.get('work_type_id', worker.work_type_id)
    
    if new_work_place_id is not None:
        work_place = db.query(WorkPlace).filter(WorkPlace.id == new_work_place_id).first()
        if not work_place:
            raise ResourceNotFoundError("Work Place", new_work_place_id)
        if work_place.parent_site_id != new_site_id:
            site = db.query(Site).filter(Site.id == new_site_id).first()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Work place '{work_place.name}' does not belong to site '{site.name if site else 'Unknown'}'"
            )
    
    if (new_employee_id != worker.employee_id or 
        new_site_id != worker.site_id or 
        new_work_type_id != worker.work_type_id):
        
        existing = db.query(Worker).filter(
            Worker.employee_id == new_employee_id,
            Worker.site_id == new_site_id,
            Worker.work_type_id == new_work_type_id,
            Worker.id != worker_id
        ).first()
        
        if existing:
            site = db.query(Site).filter(Site.id == new_site_id).first()
            work_type = db.query(WorkType).filter(WorkType.id == new_work_type_id).first()
            
            raise DuplicateEmployeeIDError(
                employee_id=new_employee_id,
                site_name=site.name if site else "Unknown",
                site_code=site.code if site else "N/A",
                work_type_name=work_type.name if work_type else "Unknown",
                work_type_code=work_type.code if work_type else "N/A",
                existing_worker={
                    "id": existing.id,
                    "name": existing.full_name
                }
            )
    
    for field, value in update_data.items():
        setattr(worker, field, value)
    
    try:
        db.commit()
        db.refresh(worker)
    except IntegrityError as e:
        db.rollback()
        if "uq_worker_employee_id_site_work_type" in str(e.orig):
            site = db.query(Site).filter(Site.id == worker.site_id).first()
            work_type = db.query(WorkType).filter(WorkType.id == worker.work_type_id).first()
            
            raise DuplicateEmployeeIDError(
                employee_id=worker.employee_id,
                site_name=site.name if site else "Unknown",
                site_code=site.code if site else "N/A",
                work_type_name=work_type.name if work_type else "Unknown",
                work_type_code=work_type.code if work_type else "N/A"
            )
        elif "national_id" in str(e.orig):
            raise DuplicateNationalIDError(worker.national_id or "Unknown")
        else:
            raise DatabaseConstraintError(
                constraint_name="unknown",
                message="Unable to update worker due to data conflict. Please verify all input data."
            )
    
    worker_with_relations = db.query(Worker).options(
        joinedload(Worker.site),
        joinedload(Worker.work_place).joinedload(WorkPlace.supervisor),
        joinedload(Worker.work_type),
        joinedload(Worker.supervisor)
    ).filter(Worker.id == worker.id).first()
    
    return enrich_worker_response(worker_with_relations)


@router.delete("/{worker_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_worker(
    worker_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))
):
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if not worker:
        raise ResourceNotFoundError("Worker", worker_id)
    
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
        raise ResourceNotFoundError("Worker", worker_id)
    
    qr_code = qr_service.generate_worker_qr(
        worker_id=worker.id,
        employee_id=worker.employee_id,
        full_name=worker.full_name,
        site_id=worker.site_id
    )
    
    worker.qr_code = qr_code
    db.commit()
    
    return {"qr_code": qr_code, "employee_id": worker.employee_id}
