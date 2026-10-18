# Employee ID Uniqueness Constraint

## Overview

The EthioWorkforce system implements a **composite unique constraint** on employee IDs to ensure that:
- Each employee ID is unique within a combination of **Site** and **Work Type**
- The same employee ID can be reused across different sites or work types
- This provides flexibility while maintaining data integrity

---

## Database Constraint

### Constraint Definition

```sql
CONSTRAINT uq_worker_employee_id_site_work_type 
UNIQUE (employee_id, site_id, work_type_id)
```

### What This Means

**✅ Allowed:**
- Worker with Employee ID `EMP-001` at Site A as a Carpenter
- Worker with Employee ID `EMP-001` at Site B as a Carpenter (different site)
- Worker with Employee ID `EMP-001` at Site A as an Electrician (different work type)

**❌ NOT Allowed:**
- Two workers with Employee ID `EMP-001` at Site A as Carpenters (duplicate)

---

## API Error Responses

### Duplicate Employee ID Error (409 Conflict)

When attempting to create or update a worker with a duplicate employee ID for the same site and work type:

```json
{
  "detail": {
    "error": "DUPLICATE_EMPLOYEE_ID",
    "message": "Employee ID 'EMP-001' is already assigned to another worker at site 'Bole Construction Site' for work type 'Carpenter'.",
    "details": {
      "employee_id": "EMP-001",
      "site": "Bole Construction Site",
      "site_code": "SITE-001",
      "work_type": "Carpenter",
      "work_type_code": "CARP-001",
      "existing_worker": {
        "id": 123,
        "name": "John Doe"
      }
    },
    "suggestion": "Please use a different Employee ID or verify if this is a duplicate entry."
  }
}
```

### Response Structure

| Field | Description |
|-------|-------------|
| `error` | Error code for programmatic handling |
| `message` | Human-readable error message |
| `details` | Comprehensive information about the conflict |
| `suggestion` | Actionable guidance for resolving the error |

---

## Migration

### Migration File
`backend/alembic/versions/017_unique_employee_id_per_work_type.py`

### Running the Migration

```bash
cd backend
alembic upgrade head
```

### Migration Actions

1. Drops the old unique index on `employee_id`
2. Creates a new non-unique index on `employee_id` (for query performance)
3. Adds composite unique constraint on `(employee_id, site_id, work_type_id)`

---

## Code Examples

### Creating a Worker

```python
from app.schemas.worker import WorkerCreate

worker_data = WorkerCreate(
    employee_id="EMP-001",
    full_name="Jane Smith",
    site_id=1,              # Bole Construction Site
    work_type_id=5,         # Carpenter
    hire_date="2026-01-15"
)

# This will succeed if no other Carpenter exists with EMP-001 at Site 1
response = requests.post("/api/v1/workers/", json=worker_data)
```

### Error Handling (Python Client)

```python
import requests

try:
    response = requests.post("/api/v1/workers/", json=worker_data)
    response.raise_for_status()
except requests.exceptions.HTTPError as e:
    if e.response.status_code == 409:
        error_detail = e.response.json()["detail"]
        if error_detail["error"] == "DUPLICATE_EMPLOYEE_ID":
            print(f"Conflict: {error_detail['message']}")
            print(f"Existing worker: {error_detail['details']['existing_worker']['name']}")
```

### Error Handling (JavaScript Client)

```javascript
try {
  const response = await fetch('/api/v1/workers/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(workerData)
  });
  
  if (!response.ok) {
    const error = await response.json();
    
    if (error.detail.error === 'DUPLICATE_EMPLOYEE_ID') {
      console.error('Duplicate Employee ID:', error.detail.message);
      console.log('Site:', error.detail.details.site);
      console.log('Work Type:', error.detail.details.work_type);
      console.log('Existing Worker:', error.detail.details.existing_worker.name);
    }
  }
} catch (err) {
  console.error('Request failed:', err);
}
```

---

## Custom Exception Classes

### DuplicateEmployeeIDError

**Location:** `app/core/exceptions.py`

```python
from app.core.exceptions import DuplicateEmployeeIDError

raise DuplicateEmployeeIDError(
    employee_id="EMP-001",
    site_name="Bole Construction Site",
    site_code="SITE-001",
    work_type_name="Carpenter",
    work_type_code="CARP-001",
    existing_worker={
        "id": 123,
        "name": "John Doe"
    }
)
```

### Other Custom Exceptions

- `ResourceNotFoundError` - When a resource doesn't exist
- `UnauthorizedAccessError` - When user lacks permission
- `DuplicateNationalIDError` - When national ID is already registered
- `ValidationError` - When input validation fails
- `DatabaseConstraintError` - Generic database constraint violations

---

## Best Practices

### 1. Employee ID Naming Conventions

Choose a consistent format for employee IDs:

```
✅ GOOD:
- SITE-001-EMP-0001
- EMP-2026-001
- CARP-001

❌ AVOID:
- Random strings without pattern
- Very short IDs (prone to conflicts)
```

### 2. Pre-Validation

Before creating a worker, optionally check for existing IDs:

```python
existing = db.query(Worker).filter(
    Worker.employee_id == new_employee_id,
    Worker.site_id == site_id,
    Worker.work_type_id == work_type_id
).first()

if existing:
    # Show warning or suggest alternative ID
```

### 3. User Interface Guidance

**Frontend should:**
- Show clear error messages from the API
- Display existing worker information when conflict occurs
- Suggest alternative employee IDs
- Allow users to search for existing employees before creating duplicates

---

## Testing

### Test Case: Create Duplicate Employee ID

```python
def test_duplicate_employee_id():
    # Create first worker
    worker1 = {
        "employee_id": "TEST-001",
        "full_name": "Test Worker 1",
        "site_id": 1,
        "work_type_id": 1
    }
    response1 = client.post("/api/v1/workers/", json=worker1)
    assert response1.status_code == 201
    
    # Try to create duplicate
    worker2 = {
        "employee_id": "TEST-001",
        "full_name": "Test Worker 2",
        "site_id": 1,  # Same site
        "work_type_id": 1  # Same work type
    }
    response2 = client.post("/api/v1/workers/", json=worker2)
    assert response2.status_code == 409
    assert response2.json()["detail"]["error"] == "DUPLICATE_EMPLOYEE_ID"
```

### Test Case: Allow Same ID in Different Context

```python
def test_same_employee_id_different_site():
    worker1 = {
        "employee_id": "TEST-001",
        "site_id": 1,
        "work_type_id": 1
    }
    response1 = client.post("/api/v1/workers/", json=worker1)
    assert response1.status_code == 201
    
    # Same employee ID, different site - should succeed
    worker2 = {
        "employee_id": "TEST-001",
        "site_id": 2,  # Different site
        "work_type_id": 1
    }
    response2 = client.post("/api/v1/workers/", json=worker2)
    assert response2.status_code == 201
```

---

## Troubleshooting

### Issue: Migration fails with "constraint does not exist"

**Solution:** The old constraint name might be different. Check existing constraints:

```sql
SELECT conname 
FROM pg_constraint 
WHERE conrelid = 'workers'::regclass;
```

### Issue: Duplicate entries already exist in database

**Solution:** Clean up duplicates before running migration:

```sql
-- Find duplicates
SELECT employee_id, site_id, work_type_id, COUNT(*) 
FROM workers 
GROUP BY employee_id, site_id, work_type_id 
HAVING COUNT(*) > 1;

-- Review and delete duplicates manually
```

---

## Support

For questions or issues:
1. Check API error response `detail.suggestion` field
2. Review this documentation
3. Contact system administrator

---

**Version:** 1.0  
**Last Updated:** February 1, 2026  
**Migration:** `017_unique_employee_id_per_work_type`
