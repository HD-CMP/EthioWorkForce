from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime

from app.core.database import get_db
from app.api.deps import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.leave import Leave, LeaveStatus, LeaveType
from app.models.worker import Worker
from app.schemas.leave import LeaveCreate, LeaveUpdate, LeaveResponse, LeaveApproval
from app.models.audit_log import AuditLog, ActionType

router = APIRouter()


@router.post("", response_model=LeaveResponse, status_code=status.HTTP_201_CREATED)
def create_leave_request(
    leave_data: LeaveCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    worker = db.query(Worker).filter(Worker.id == leave_data.worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    
    if leave_data.end_date < leave_data.start_date:
        raise HTTPException(status_code=400, detail="End date must be after start date")
    
    days_count = (leave_data.end_date - leave_data.start_date).days + 1
    
    leave = Leave(
        worker_id=leave_data.worker_id,
        leave_type=leave_data.leave_type,
        start_date=leave_data.start_date,
        end_date=leave_data.end_date,
        days_count=days_count,
        reason=leave_data.reason,
        requested_by_user_id=current_user.id
    )
    
    db.add(leave)
    db.commit()
    db.refresh(leave)
    
    audit_log = AuditLog(
        user_id=current_user.id,
        action=ActionType.CREATE,
        entity_type="leave",
        entity_id=leave.id,
        details=f"Leave request created for worker {worker.full_name}"
    )
    db.add(audit_log)
    db.commit()
    
    return leave


@router.get("", response_model=List[LeaveResponse])
def list_leaves(
    worker_id: Optional[int] = Query(None),
    status: Optional[LeaveStatus] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Leave)
    
    if worker_id:
        query = query.filter(Leave.worker_id == worker_id)
    
    if status:
        query = query.filter(Leave.status == status)
    
    query = query.order_by(Leave.created_at.desc())
    leaves = query.offset(skip).limit(limit).all()
    
    return leaves


@router.get("/{leave_id}", response_model=LeaveResponse)
def get_leave(
    leave_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    leave = db.query(Leave).filter(Leave.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="Leave request not found")
    
    return leave


@router.post("/{leave_id}/approve", response_model=LeaveResponse)
def approve_leave(
    leave_id: int,
    approval: LeaveApproval,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ADMIN, UserRole.SITE_ADMIN]))
):
    leave = db.query(Leave).filter(Leave.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="Leave request not found")
    
    if leave.status != LeaveStatus.PENDING:
        raise HTTPException(status_code=400, detail="Leave request already processed")
    
    leave.status = LeaveStatus.APPROVED if approval.approved else LeaveStatus.REJECTED
    leave.approved_by_user_id = current_user.id
    leave.approved_at = date.today()
    
    if not approval.approved and approval.rejection_reason:
        leave.rejection_reason = approval.rejection_reason
    
    db.commit()
    db.refresh(leave)
    
    audit_log = AuditLog(
        user_id=current_user.id,
        action=ActionType.UPDATE,
        entity_type="leave",
        entity_id=leave.id,
        details=f"Leave request {'approved' if approval.approved else 'rejected'}"
    )
    db.add(audit_log)
    db.commit()
    
    return leave


@router.delete("/{leave_id}", status_code=status.HTTP_204_NO_CONTENT)
def cancel_leave(
    leave_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    leave = db.query(Leave).filter(Leave.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="Leave request not found")
    
    if leave.status == LeaveStatus.APPROVED and current_user.role not in [UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Cannot cancel approved leave")
    
    leave.status = LeaveStatus.CANCELLED
    db.commit()
    
    audit_log = AuditLog(
        user_id=current_user.id,
        action=ActionType.DELETE,
        entity_type="leave",
        entity_id=leave.id,
        details=f"Leave request cancelled"
    )
    db.add(audit_log)
    db.commit()
    
    return None
