from typing import Dict, Any, Optional
from fastapi import HTTPException, status


class EthioWorkforceException(HTTPException):
    """Base exception class for EthioWorkforce application"""
    
    def __init__(
        self,
        status_code: int,
        error_code: str,
        message: str,
        details: Optional[Dict[str, Any]] = None,
        suggestion: Optional[str] = None
    ):
        detail = {
            "error": error_code,
            "message": message
        }
        
        if details:
            detail["details"] = details
        
        if suggestion:
            detail["suggestion"] = suggestion
        
        super().__init__(status_code=status_code, detail=detail)


class DuplicateEmployeeIDError(EthioWorkforceException):
    """Raised when attempting to create a worker with duplicate employee_id for a site and work type"""
    
    def __init__(
        self,
        employee_id: str,
        site_name: str,
        site_code: str,
        work_type_name: str,
        work_type_code: str,
        existing_worker: Optional[Dict[str, Any]] = None
    ):
        details = {
            "employee_id": employee_id,
            "site": site_name,
            "site_code": site_code,
            "work_type": work_type_name,
            "work_type_code": work_type_code
        }
        
        if existing_worker:
            details["existing_worker"] = existing_worker
        
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            error_code="DUPLICATE_EMPLOYEE_ID",
            message=f"Employee ID '{employee_id}' is already assigned to another worker at site '{site_name}' for work type '{work_type_name}'.",
            details=details,
            suggestion="Please use a different Employee ID or verify if this is a duplicate entry."
        )


class DuplicateNationalIDError(EthioWorkforceException):
    """Raised when attempting to create a worker with duplicate national_id"""
    
    def __init__(self, national_id: str):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            error_code="DUPLICATE_NATIONAL_ID",
            message=f"National ID '{national_id}' is already registered to another worker.",
            suggestion="Please verify the National ID number or check if this worker already exists in the system."
        )


class ResourceNotFoundError(EthioWorkforceException):
    """Raised when a requested resource is not found"""
    
    def __init__(self, resource_type: str, identifier: Any):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            error_code="RESOURCE_NOT_FOUND",
            message=f"{resource_type} with identifier '{identifier}' not found.",
            suggestion="Please verify the identifier and try again."
        )


class UnauthorizedAccessError(EthioWorkforceException):
    """Raised when user attempts to access a resource without proper authorization"""
    
    def __init__(self, resource_type: str, action: str):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            error_code="UNAUTHORIZED_ACCESS",
            message=f"You do not have permission to {action} this {resource_type}.",
            suggestion="Contact your system administrator if you believe you should have access."
        )


class ValidationError(EthioWorkforceException):
    """Raised when input validation fails"""
    
    def __init__(self, field: str, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            error_code="VALIDATION_ERROR",
            message=message,
            details=details or {"field": field},
            suggestion="Please correct the input and try again."
        )


class DatabaseConstraintError(EthioWorkforceException):
    """Raised when a database constraint is violated"""
    
    def __init__(self, constraint_name: str, message: str):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            error_code="DATABASE_CONSTRAINT_ERROR",
            message=message,
            details={"constraint": constraint_name},
            suggestion="Please verify your input data meets all requirements."
        )
