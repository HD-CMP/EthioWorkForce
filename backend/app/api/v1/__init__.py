from fastapi import APIRouter

from app.api.v1 import (
    auth, users, sites, work_types, workers, attendance, overtime, payroll, 
    reports, sync, leaves, role_changes, disputes, registration, work_places, payment_periods, notifications, roles
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(registration.router, prefix="/registration", tags=["User Registration"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(roles.router, prefix="/roles", tags=["Roles"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(sites.router, prefix="/sites", tags=["Sites"])
api_router.include_router(work_places.router, prefix="/work-places", tags=["Work Places"])
api_router.include_router(work_types.router, prefix="/work-types", tags=["Work Types"])
api_router.include_router(workers.router, prefix="/workers", tags=["Workers"])
api_router.include_router(attendance.router, prefix="/attendance", tags=["Attendance"])
api_router.include_router(overtime.router, prefix="/overtime", tags=["Overtime"])
api_router.include_router(payroll.router, prefix="/payroll", tags=["Payroll"])
api_router.include_router(reports.router, prefix="/reports", tags=["Reports & Exports"])
api_router.include_router(sync.router, prefix="/sync", tags=["Synchronization"])
api_router.include_router(leaves.router, prefix="/leaves", tags=["Leave Management"])
api_router.include_router(role_changes.router, prefix="/role-changes", tags=["Role Changes"])
api_router.include_router(disputes.router, prefix="/disputes", tags=["Attendance Disputes"])
api_router.include_router(payment_periods.router, prefix="/payment-periods", tags=["Payment Periods"])
