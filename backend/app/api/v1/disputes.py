from fastapi import APIRouter, Depends, HTTPException, status, Query, File, UploadFile
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import os
import uuid

from app.core.database import get_db
from app.api.deps import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.attendance_dispute import AttendanceDispute, DisputeStatus, DisputeResolution
from app.models.attendance import Attendance
from app.models.worker import Worker
from app.schemas.dispute import DisputeCreate, DisputeResponse, DisputeResolution as DisputeResolutionSchema
from app.models.audit_log import AuditLog, ActionType

router = APIRouter()


@router.post("", response_model=DisputeResponse, status_code=status.HTTP_201_CREATED)
async def create_dispute(
    dispute_data: DisputeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    attendance = db.query(Attendance).filter(Attendance.id == dispute_data.attendance_id).first()
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    worker = db.query(Worker).filter(Worker.id == attendance.worker_id).first()
    
    dispute = AttendanceDispute(
        attendance_id=dispute_data.attendance_id,
        worker_id=attendance.worker_id,
        dispute_reason=dispute_data.dispute_reason,
        evidence_description=dispute_data.evidence_description,
        filed_by_user_id=current_user.id
    )
    
    db.add(dispute)
    db.commit()
    db.refresh(dispute)
    
    audit_log = AuditLog(
        user_id=current_user.id,
        action=ActionType.CREATE,
        entity_type="attendance_dispute",
        entity_id=dispute.id,
        details=f"Attendance dispute filed for worker {worker.full_name}"
    )
    db.add(audit_log)
    db.commit()
    
    return dispute


@router.post("/{dispute_id}/upload-evidence")
async def upload_evidence(
    dispute_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    dispute = db.query(AttendanceDispute).filter(AttendanceDispute.id == dispute_id).first()
    if not dispute:
        raise HTTPException(status_code=404, detail="Dispute not found")
    
    if dispute.filed_by_user_id != current_user.id and current_user.role not in [UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Not authorized to upload evidence")
    
    allowed_extensions = {'.jpg', '.jpeg', '.png', '.pdf'}
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Invalid file type. Allowed: jpg, png, pdf")
    
    upload_dir = "uploads/disputes"
    os.makedirs(upload_dir, exist_ok=True)
    
    file_uuid = str(uuid.uuid4())
    file_path = os.path.join(upload_dir, f"{file_uuid}{file_ext}")
    
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    dispute.evidence_file_path = file_path
    db.commit()
    
    return {"message": "Evidence uploaded successfully", "file_path": file_path}


@router.get("", response_model=List[DisputeResponse])
def list_disputes(
    worker_id: Optional[int] = Query(None),
    status: Optional[DisputeStatus] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(AttendanceDispute)
    
    if worker_id:
        query = query.filter(AttendanceDispute.worker_id == worker_id)
    
    if status:
        query = query.filter(AttendanceDispute.status == status)
    
    query = query.order_by(AttendanceDispute.created_at.desc())
    disputes = query.offset(skip).limit(limit).all()
    
    return disputes


@router.get("/{dispute_id}", response_model=DisputeResponse)
def get_dispute(
    dispute_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    dispute = db.query(AttendanceDispute).filter(AttendanceDispute.id == dispute_id).first()
    if not dispute:
        raise HTTPException(status_code=404, detail="Dispute not found")
    
    return dispute


@router.post("/{dispute_id}/resolve", response_model=DisputeResponse)
def resolve_dispute(
    dispute_id: int,
    resolution: DisputeResolutionSchema,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ADMIN, UserRole.SITE_ADMIN]))
):
    dispute = db.query(AttendanceDispute).filter(AttendanceDispute.id == dispute_id).first()
    if not dispute:
        raise HTTPException(status_code=404, detail="Dispute not found")
    
    if dispute.status == DisputeStatus.RESOLVED:
        raise HTTPException(status_code=400, detail="Dispute already resolved")
    
    dispute.status = DisputeStatus.RESOLVED
    dispute.resolution = resolution.resolution
    dispute.resolution_notes = resolution.resolution_notes
    dispute.resolved_by_user_id = current_user.id
    dispute.resolved_at = datetime.utcnow()
    
    if resolution.resolution == DisputeResolution.ATTENDANCE_CORRECTED:
        attendance = db.query(Attendance).filter(Attendance.id == dispute.attendance_id).first()
        if attendance:
            attendance.override_reason = f"Dispute resolved: {resolution.resolution_notes}"
    
    db.commit()
    db.refresh(dispute)
    
    audit_log = AuditLog(
        user_id=current_user.id,
        action=ActionType.UPDATE,
        entity_type="attendance_dispute",
        entity_id=dispute.id,
        details=f"Dispute resolved: {resolution.resolution}"
    )
    db.add(audit_log)
    db.commit()
    
    return dispute


@router.post("/{dispute_id}/review", response_model=DisputeResponse)
def mark_under_review(
    dispute_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ADMIN, UserRole.SITE_ADMIN]))
):
    dispute = db.query(AttendanceDispute).filter(AttendanceDispute.id == dispute_id).first()
    if not dispute:
        raise HTTPException(status_code=404, detail="Dispute not found")
    
    dispute.status = DisputeStatus.UNDER_REVIEW
    db.commit()
    db.refresh(dispute)
    
    return dispute
