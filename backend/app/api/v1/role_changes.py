from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date

from app.core.database import get_db
from app.api.deps import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.role_change import RoleChange, RoleChangeStatus
from app.models.worker import Worker
from app.models.work_type import WorkType
from app.schemas.role_change import RoleChangeCreate, RoleChangeResponse, RoleChangeApproval
from app.models.audit_log import AuditLog, ActionType

router = APIRouter()


@router.post("", response_model=RoleChangeResponse, status_code=status.HTTP_201_CREATED)
def create_role_change_request(
    role_change_data: RoleChangeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ADMIN, UserRole.HR_OFFICER]))
):
    worker = db.query(Worker).filter(Worker.id == role_change_data.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    new_work_type = db.query(WorkType).filter(WorkType.id == role_change_data.new_work_type_id).first()
    if not new_work_type:
        raise HTTPException(status_code=404, detail="New work type not found")
    
    role_change = RoleChange(
        worker_id=role_change_data.worker_id,
        old_work_type_id=worker.work_type_id,
        new_work_type_id=role_change_data.new_work_type_id,
        old_site_id=worker.site_id,
        new_site_id=role_change_data.new_site_id or worker.site_id,
        effective_date=role_change_data.effective_date,
        reason=role_change_data.reason,
        requested_by_user_id=current_user.id
    )
    
    db.add(role_change)
    db.commit()
    db.refresh(role_change)
    
    audit_log = AuditLog(
        user_id=current_user.id,
        action=ActionType.CREATE,
        entity_type="role_change",
        entity_id=role_change.id,
        details=f"Role change request created for worker {worker.full_name}"
    )
    db.add(audit_log)
    db.commit()
    
    return role_change


@router.get("", response_model=List[RoleChangeResponse])
def list_role_changes(
    worker_id: Optional[int] = Query(None),
    status: Optional[RoleChangeStatus] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(RoleChange)
    
    if worker_id:
        query = query.filter(RoleChange.worker_id == worker_id)
    
    if status:
        query = query.filter(RoleChange.status == status)
    
    query = query.order_by(RoleChange.created_at.desc())
    role_changes = query.offset(skip).limit(limit).all()
    
    return role_changes


@router.get("/{role_change_id}", response_model=RoleChangeResponse)
def get_role_change(
    role_change_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    role_change = db.query(RoleChange).filter(RoleChange.id == role_change_id).first()
    if not role_change:
        raise HTTPException(status_code=404, detail="Role change request not found")
    
    return role_change


@router.post("/{role_change_id}/approve", response_model=RoleChangeResponse)
def approve_role_change(
    role_change_id: int,
    approval: RoleChangeApproval,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ADMIN]))
):
    role_change = db.query(RoleChange).filter(RoleChange.id == role_change_id).first()
    if not role_change:
        raise HTTPException(status_code=404, detail="Role change request not found")
    
    if role_change.status != RoleChangeStatus.PENDING:
        raise HTTPException(status_code=400, detail="Role change request already processed")
    
    role_change.status = RoleChangeStatus.APPROVED if approval.approved else RoleChangeStatus.REJECTED
    role_change.approved_by_user_id = current_user.id
    
    if approval.notes:
        role_change.notes = approval.notes
    
    db.commit()
    db.refresh(role_change)
    
    audit_log = AuditLog(
        user_id=current_user.id,
        action=ActionType.UPDATE,
        entity_type="role_change",
        entity_id=role_change.id,
        details=f"Role change request {'approved' if approval.approved else 'rejected'}"
    )
    db.add(audit_log)
    db.commit()
    
    return role_change


@router.post("/{role_change_id}/implement", response_model=RoleChangeResponse)
def implement_role_change(
    role_change_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ADMIN]))
):
    role_change = db.query(RoleChange).filter(RoleChange.id == role_change_id).first()
    if not role_change:
        raise HTTPException(status_code=404, detail="Role change request not found")
    
    if role_change.status != RoleChangeStatus.APPROVED:
        raise HTTPException(status_code=400, detail="Role change must be approved first")
    
    if role_change.effective_date > date.today():
        raise HTTPException(status_code=400, detail="Cannot implement future-dated role change")
    
    worker = db.query(Worker).filter(Worker.id == role_change.worker_id).first()
    worker.work_type_id = role_change.new_work_type_id
    worker.site_id = role_change.new_site_id
    
    role_change.status = RoleChangeStatus.IMPLEMENTED
    role_change.implemented_at = date.today()
    
    db.commit()
    db.refresh(role_change)
    
    audit_log = AuditLog(
        user_id=current_user.id,
        action=ActionType.UPDATE,
        entity_type="role_change",
        entity_id=role_change.id,
        details=f"Role change implemented for worker {worker.full_name}"
    )
    db.add(audit_log)
    db.commit()
    
    return role_change
