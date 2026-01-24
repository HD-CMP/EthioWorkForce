# EthioWorkForce - Testing Strategy & Quality Assurance

**Version**: 1.0.0  
**Date**: January 23, 2026

---

## Table of Contents
1. [Testing Philosophy](#testing-philosophy)
2. [Test Environment Setup](#test-environment-setup)
3. [Unit Testing](#unit-testing)
4. [Integration Testing](#integration-testing)
5. [End-to-End Testing](#end-to-end-testing)
6. [Performance Testing](#performance-testing)
7. [Security Testing](#security-testing)
8. [User Acceptance Testing](#user-acceptance-testing)

---

## 1. Testing Philosophy

### 1.1 Testing Pyramid

```
                /\
               /  \
              / E2E \          10% - End-to-End Tests
             /______\
            /        \
           /Integration\       30% - Integration Tests
          /____________\
         /              \
        /   Unit Tests   \     60% - Unit Tests
       /__________________\
```

### 1.2 Quality Goals

- **Test Coverage**: Minimum 80% code coverage
- **Critical Path Coverage**: 100% for payment calculations
- **Regression Prevention**: All bugs get a test case
- **Documentation**: Tests serve as living documentation

---

## 2. Test Environment Setup

### 2.1 Backend Test Setup

```bash
cd backend

# Create test database
sudo -u postgres psql
CREATE DATABASE ethioworkforce_test;
GRANT ALL PRIVILEGES ON DATABASE ethioworkforce_test TO ethioworkforce_user;
\q

# Install test dependencies
pip install pytest pytest-asyncio pytest-cov pytest-mock httpx

# Run tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html --cov-report=term
```

### 2.2 Test Configuration

Create `backend/pytest.ini`:

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    -v
    --tb=short
    --strict-markers
    --disable-warnings
markers =
    unit: Unit tests
    integration: Integration tests
    slow: Tests that take a long time
    critical: Critical business logic tests
```

### 2.3 Test Environment Variables

Create `backend/.env.test`:

```bash
ENVIRONMENT=test
DEBUG=true
DATABASE_URL=postgresql://ethioworkforce_user:password@localhost/ethioworkforce_test
SECRET_KEY=test_secret_key_for_testing_only
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

---

## 3. Unit Testing

### 3.1 Payroll Calculator Tests

Create `backend/tests/test_payroll_calculator.py`:

```python
import pytest
from app.services.payroll_calculator import PayrollCalculator
from app.models.work_type import WorkType, PaymentMode, TaxRule


class TestPayrollCalculator:
    """Test payroll calculation engine"""
    
    def test_daily_worker_no_deductions(self):
        """Daily workers should receive full gross pay"""
        work_type = WorkType(
            payment_mode=PaymentMode.DAILY_RATE,
            tax_rule=TaxRule.DAILY_CASUAL,
            daily_rate=300
        )
        
        calculator = PayrollCalculator()
        result = calculator.calculate_daily_worker(
            daily_rate=300,
            days_worked=20
        )
        
        assert result['gross_pay'] == 6000
        assert result['income_tax'] == 0
        assert result['pension'] == 0
        assert result['net_pay'] == 6000
    
    def test_permanent_worker_with_tax(self):
        """Permanent workers should have tax and pension deducted"""
        calculator = PayrollCalculator()
        result = calculator.calculate_permanent_worker(
            gross_salary=20000
        )
        
        assert result['gross_pay'] == 20000
        assert result['income_tax'] > 0
        assert result['pension'] == 1400  # 7% of 20000
        assert result['net_pay'] < result['gross_pay']
    
    def test_erca_tax_brackets(self):
        """Test Ethiopian tax calculation accuracy"""
        calculator = PayrollCalculator()
        
        # Test bracket 1: 0 ETB (no tax)
        assert calculator.calculate_income_tax(600) == 0
        
        # Test bracket 2: 10% for income between 600-1650
        assert calculator.calculate_income_tax(1000) == 40  # (1000-600)*0.1
        
        # Test higher brackets
        tax_5000 = calculator.calculate_income_tax(5000)
        assert tax_5000 > 0
        assert tax_5000 < 5000
    
    def test_overtime_calculation(self):
        """Test overtime calculation with multipliers"""
        calculator = PayrollCalculator()
        result = calculator.calculate_overtime(
            hourly_rate=100,
            overtime_hours=10,
            multiplier=1.5
        )
        
        assert result == 1500  # 100 * 10 * 1.5
```

### 3.2 Ethiopian Calendar Tests

Already exists at `backend/tests/test_ethiopian_calendar.py` - verify it works:

```bash
pytest backend/tests/test_ethiopian_calendar.py -v
```

### 3.3 Authentication Tests

Create `backend/tests/test_auth.py`:

```python
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token, verify_password, get_password_hash


client = TestClient(app)


class TestAuthentication:
    
    def test_password_hashing(self):
        """Test password hashing and verification"""
        password = "SecurePass123!"
        hashed = get_password_hash(password)
        
        assert hashed != password
        assert verify_password(password, hashed) is True
        assert verify_password("wrong_password", hashed) is False
    
    def test_jwt_token_creation(self):
        """Test JWT token generation"""
        token = create_access_token(data={"user_id": 1, "username": "testuser"})
        
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 50
    
    def test_login_success(self):
        """Test successful login"""
        response = client.post("/api/v1/auth/login", json={
            "username": "admin",
            "password": "admin123"
        })
        
        if response.status_code == 200:
            data = response.json()
            assert "access_token" in data
            assert "refresh_token" in data
            assert data["token_type"] == "bearer"
    
    def test_login_invalid_credentials(self):
        """Test login with wrong credentials"""
        response = client.post("/api/v1/auth/login", json={
            "username": "admin",
            "password": "wrongpassword"
        })
        
        assert response.status_code == 401
```

---

## 4. Integration Testing

### 4.1 API Endpoint Tests

Create `backend/tests/test_api_endpoints.py`:

```python
import pytest
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


class TestAPIEndpoints:
    
    @pytest.fixture
    def auth_headers(self):
        """Get authentication headers for protected endpoints"""
        response = client.post("/api/v1/auth/login", json={
            "username": "admin",
            "password": "admin123"
        })
        if response.status_code == 200:
            token = response.json()["access_token"]
            return {"Authorization": f"Bearer {token}"}
        return {}
    
    def test_health_endpoint(self):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
    
    def test_create_worker(self, auth_headers):
        """Test worker creation"""
        worker_data = {
            "employee_id": "EMP001",
            "full_name": "Test Worker",
            "site_id": 1,
            "work_type_id": 1,
            "hire_date": "2026-01-01"
        }
        
        response = client.post(
            "/api/v1/workers",
            json=worker_data,
            headers=auth_headers
        )
        
        if response.status_code == 201:
            data = response.json()
            assert data["employee_id"] == "EMP001"
            assert data["full_name"] == "Test Worker"
    
    def test_mark_attendance(self, auth_headers):
        """Test attendance marking"""
        attendance_data = {
            "worker_id": 1,
            "site_id": 1,
            "attendance_date": "2026-01-23",
            "status": "present",
            "method": "qr_scan"
        }
        
        response = client.post(
            "/api/v1/attendance",
            json=attendance_data,
            headers=auth_headers
        )
        
        assert response.status_code in [200, 201]
    
    def test_unauthorized_access(self):
        """Test that protected endpoints require authentication"""
        response = client.get("/api/v1/workers")
        assert response.status_code == 401
```

### 4.2 Database Integration Tests

Create `backend/tests/test_database.py`:

```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models.base import Base
from app.models.worker import Worker
from app.core.config import settings


@pytest.fixture
def test_db():
    """Create test database session"""
    engine = create_engine(settings.DATABASE_URL)
    TestingSessionLocal = sessionmaker(bind=engine)
    
    Base.metadata.create_all(bind=engine)
    
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


class TestDatabaseOperations:
    
    def test_create_worker(self, test_db):
        """Test creating worker in database"""
        worker = Worker(
            employee_id="TEST001",
            full_name="Test Worker",
            site_id=1,
            work_type_id=1,
            hire_date="2026-01-01"
        )
        
        test_db.add(worker)
        test_db.commit()
        test_db.refresh(worker)
        
        assert worker.id is not None
        assert worker.employee_id == "TEST001"
    
    def test_worker_relationships(self, test_db):
        """Test worker relationships with attendance and payroll"""
        # Implementation depends on your models
        pass
```

---

## 5. End-to-End Testing

### 5.1 E2E Test Scenarios

Create `backend/tests/test_e2e_workflows.py`:

```python
import pytest
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


class TestCompleteWorkflows:
    """Test complete business workflows end-to-end"""
    
    def test_complete_payroll_workflow(self):
        """Test: Worker creation → Attendance → Payroll calculation"""
        
        # 1. Login
        login_response = client.post("/api/v1/auth/login", json={
            "username": "admin",
            "password": "admin123"
        })
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Create worker
        worker_response = client.post("/api/v1/workers", json={
            "employee_id": "E2E001",
            "full_name": "E2E Test Worker",
            "site_id": 1,
            "work_type_id": 1,
            "hire_date": "2026-01-01"
        }, headers=headers)
        
        worker_id = worker_response.json()["id"]
        
        # 3. Mark attendance for 20 days
        for day in range(1, 21):
            client.post("/api/v1/attendance", json={
                "worker_id": worker_id,
                "site_id": 1,
                "attendance_date": f"2026-01-{day:02d}",
                "status": "present",
                "method": "manual_entry"
            }, headers=headers)
        
        # 4. Generate payroll
        payroll_response = client.post("/api/v1/payroll", json={
            "site_id": 1,
            "period_start": "2026-01-01",
            "period_end": "2026-01-31"
        }, headers=headers)
        
        # 5. Verify payroll calculated correctly
        assert payroll_response.status_code == 201
        payroll = payroll_response.json()
        assert len(payroll["items"]) > 0
```

---

## 6. Performance Testing

### 6.1 Load Testing Script

Create `backend/tests/load_test.py`:

```python
import requests
import time
import statistics
from concurrent.futures import ThreadPoolExecutor


def test_endpoint_response_time(url, num_requests=100):
    """Test API endpoint response times"""
    response_times = []
    
    def make_request():
        start = time.time()
        response = requests.get(url)
        end = time.time()
        response_times.append(end - start)
        return response.status_code
    
    with ThreadPoolExecutor(max_workers=10) as executor:
        results = list(executor.map(lambda _: make_request(), range(num_requests)))
    
    print(f"Total requests: {num_requests}")
    print(f"Successful: {results.count(200)}")
    print(f"Failed: {num_requests - results.count(200)}")
    print(f"Avg response time: {statistics.mean(response_times):.3f}s")
    print(f"Max response time: {max(response_times):.3f}s")
    print(f"Min response time: {min(response_times):.3f}s")


if __name__ == "__main__":
    test_endpoint_response_time("http://localhost:8000/health")
    test_endpoint_response_time("http://localhost:8000/api/v1/workers")
```

### 6.2 Database Performance Test

```python
import time
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models.attendance import Attendance


def test_bulk_insert_performance():
    """Test database performance with large datasets"""
    engine = create_engine("postgresql://user:pass@localhost/ethioworkforce")
    Session = sessionmaker(bind=engine)
    session = Session()
    
    start = time.time()
    
    # Insert 10,000 attendance records
    for i in range(10000):
        attendance = Attendance(
            worker_id=(i % 100) + 1,
            site_id=1,
            attendance_date="2026-01-23",
            status="present",
            method="qr_scan"
        )
        session.add(attendance)
        
        if i % 1000 == 0:
            session.commit()
    
    session.commit()
    end = time.time()
    
    print(f"Inserted 10,000 records in {end-start:.2f}s")
    print(f"Rate: {10000/(end-start):.0f} records/second")
```

---

## 7. Security Testing

### 7.1 Security Test Checklist

**Authentication Tests**:
- [ ] Test SQL injection in login form
- [ ] Test weak password rejection
- [ ] Test brute force protection (account lockout)
- [ ] Test password reset security
- [ ] Test token expiration

**Authorization Tests**:
- [ ] Test role-based access control
- [ ] Test accessing resources of other users
- [ ] Test privilege escalation attempts

**Input Validation Tests**:
- [ ] Test XSS prevention
- [ ] Test file upload restrictions
- [ ] Test SQL injection in all input fields
- [ ] Test command injection

**Data Protection Tests**:
- [ ] Test password hashing (bcrypt)
- [ ] Test sensitive data encryption
- [ ] Test HTTPS enforcement
- [ ] Test secure headers

### 7.2 Security Test Script

Create `backend/tests/test_security.py`:

```python
import pytest
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


class TestSecurity:
    
    def test_sql_injection_prevention(self):
        """Test SQL injection prevention"""
        malicious_input = "admin' OR '1'='1"
        response = client.post("/api/v1/auth/login", json={
            "username": malicious_input,
            "password": "password"
        })
        
        assert response.status_code == 401
    
    def test_xss_prevention(self):
        """Test XSS script prevention"""
        xss_payload = "<script>alert('XSS')</script>"
        
        # Try to inject in worker name
        response = client.post("/api/v1/workers", json={
            "full_name": xss_payload,
            "employee_id": "XSS001"
        })
        
        # Should either reject or sanitize
        assert response.status_code in [400, 401]
    
    def test_file_upload_restrictions(self):
        """Test file upload type restrictions"""
        # Try to upload executable file
        files = {"file": ("malicious.exe", b"fake executable", "application/x-msdownload")}
        response = client.post("/api/v1/upload", files=files)
        
        assert response.status_code in [400, 415]
```

---

## 8. User Acceptance Testing (UAT)

### 8.1 UAT Test Plan

**Participants**:
- Site Admin
- Supervisor
- HR Officer
- Regular Worker

**Duration**: 2 weeks

**Test Scenarios**:

1. **Worker Onboarding**
   - [ ] Create new worker profile
   - [ ] Upload worker photo
   - [ ] Generate QR code
   - [ ] Assign to site and role

2. **Daily Attendance**
   - [ ] Scan QR code
   - [ ] Mark attendance manually
   - [ ] Override attendance status
   - [ ] Lock daily attendance

3. **Leave Management**
   - [ ] Submit leave request
   - [ ] Approve leave
   - [ ] Reject leave with reason
   - [ ] View leave balance

4. **Payroll Processing**
   - [ ] Generate monthly payroll
   - [ ] Review payroll details
   - [ ] Export to bank format
   - [ ] Generate pension report

5. **Offline Mode**
   - [ ] Disconnect internet
   - [ ] Mark attendance offline
   - [ ] Reconnect and sync
   - [ ] Verify data integrity

### 8.2 UAT Sign-off Form

```
UAT Sign-off Form

Feature: ____________________________
Tested By: __________________________
Date: _______________________________

Test Results:
☐ All features work as expected
☐ Some issues found (see below)
☐ Major issues - not ready for production

Issues Found:
1. _________________________________
2. _________________________________
3. _________________________________

Overall Assessment:
☐ Approved for production
☐ Approved with minor issues
☐ Rejected - needs more work

Signature: __________________________
```

---

## 9. Test Automation

### 9.1 CI/CD Integration

Create `.github/workflows/test.yml`:

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:12
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.9
      
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
          pip install pytest pytest-cov
      
      - name: Run tests
        run: |
          cd backend
          pytest --cov=app --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v2
```

---

**Document Owner**: EthioWorkForce QA Team  
**Last Updated**: January 23, 2026  
**Next Review**: February 23, 2026
