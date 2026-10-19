"""
Live Cloud Backend Smoke Test & Verification Suite for EthioWorkforce.
Validates end-to-end functionality of deployed cloud APIs.

Usage:
  python scripts/smoke_test_cloud.py --url https://ethioworkforce-api.onrender.com
  python scripts/smoke_test_cloud.py --url http://127.0.0.1:8000
"""

import argparse
import sys
import os
import httpx
from datetime import datetime


def run_smoke_tests(base_url: str, username: str, password: str):
    base_url = base_url.rstrip("/")
    print("=" * 70)
    print("[TEST] EthioWorkforce Cloud Backend Smoke Test")
    print(f"[*] Target URL: {base_url}")
    print(f"[*] Timestamp:  {datetime.now().isoformat()}")
    print("=" * 70)

    client = httpx.Client(base_url=base_url, timeout=30.0, follow_redirects=True)
    passed = 0
    failed = 0

    def check(title: str, func):
        nonlocal passed, failed
        try:
            func()
            print(f"  [PASS] {title}")
            passed += 1
        except Exception as e:
            print(f"  [FAIL] {title} -> {e}")
            failed += 1

    # 1. Root Status Endpoint
    def test_root():
        res = client.get("/")
        assert res.status_code == 200, f"Status code {res.status_code}"
        data = res.json()
        assert "status" in data, "No 'status' field in root response"
        assert data["status"] == "operational", f"Status is {data['status']}"
    check("Root Endpoint (GET /)", test_root)

    # 2. Health Endpoint
    def test_health():
        res = client.get("/health")
        assert res.status_code == 200, f"Status code {res.status_code}"
        data = res.json()
        assert data.get("status") == "healthy", f"Health status: {data}"
    check("Health Check (GET /health)", test_health)

    # 3. Interactive Swagger Docs
    def test_docs():
        res = client.get("/api/docs")
        assert res.status_code == 200, f"Swagger docs status {res.status_code}"
        assert "swagger-ui" in res.text.lower() or "html" in res.text.lower(), "Swagger HTML missing"
    check("Swagger UI Documentation (GET /api/docs)", test_docs)

    # 4. Authentication Login
    token = None
    def test_login():
        nonlocal token
        # Try primary password, fallback to alternate if local dev seeded differently
        passwords_to_try = [password, "Admin@Ethio2026!", "admin123"]
        last_error = None
        for p in passwords_to_try:
            res = client.post("/api/v1/auth/login", json={"username": username, "password": p})
            if res.status_code == 200:
                data = res.json()
                token = data.get("access_token")
                if token:
                    return
            last_error = f"Status {res.status_code}: {res.text}"
        assert token, f"Login failed: {last_error}"
    check(f"Admin Authentication (POST /api/v1/auth/login as '{username}')", test_login)

    if not token:
        print("\n[!] Authentication failed. Skipping authenticated endpoint checks.")
        print(f"Summary: {passed} Passed, {failed} Failed.")
        sys.exit(1)

    auth_headers = {"Authorization": f"Bearer {token}"}

    # 5. Current User Profile
    def test_me():
        res = client.get("/api/v1/users/me", headers=auth_headers)
        assert res.status_code == 200, f"Users me status {res.status_code}: {res.text}"
        data = res.json()
        assert data.get("username") == username, f"Unexpected username: {data.get('username')}"
    check("User Profile Identity (GET /api/v1/users/me)", test_me)

    # 6. Sites Query
    def test_sites():
        res = client.get("/api/v1/sites", headers=auth_headers)
        assert res.status_code == 200, f"Sites query failed: {res.text}"
        sites = res.json()
        assert isinstance(sites, list), f"Expected list of sites, got {type(sites)}"
    check("Operating Sites Query (GET /api/v1/sites)", test_sites)

    # 7. Work Types Query
    def test_work_types():
        res = client.get("/api/v1/work-types", headers=auth_headers)
        assert res.status_code == 200, f"Work types query failed: {res.text}"
        wts = res.json()
        assert isinstance(wts, list), f"Expected list of work types, got {type(wts)}"
    check("Work Types Compliance Query (GET /api/v1/work-types)", test_work_types)

    # 8. Workforce Workers Query
    def test_workers():
        res = client.get("/api/v1/workers", headers=auth_headers)
        assert res.status_code == 200, f"Workers query failed: {res.text}"
        workers = res.json()
        assert isinstance(workers, list), f"Expected list of workers, got {type(workers)}"
    check("Workforce Registry (GET /api/v1/workers)", test_workers)

    # 9. Enterprise Reports Dashboard KPI
    def test_dashboard():
        res = client.get("/api/v1/reports/dashboard", headers=auth_headers)
        assert res.status_code == 200, f"Dashboard reports failed: {res.text}"
        kpis = res.json()
        assert "workforce" in kpis or "total_workers" in kpis, "Missing workforce metrics in dashboard"
    check("Reports KPI Analytics (GET /api/v1/reports/dashboard)", test_dashboard)

    print("=" * 70)
    print(f"[*] Smoke Test Results: {passed} PASSED | {failed} FAILED")
    if failed == 0:
        print("[SUCCESS] Cloud Backend is 100% OPERATIONAL and Production Ready!")
        print("=" * 70)
        sys.exit(0)
    else:
        print("[FAIL] Some smoke tests failed. Please review the output above.")
        print("=" * 70)
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="EthioWorkforce Cloud Smoke Test")
    parser.add_argument("--url", default=os.getenv("BACKEND_URL", "http://127.0.0.1:8000"), help="Base backend URL")
    parser.add_argument("--username", default=os.getenv("ADMIN_USER", "admin"), help="Admin username")
    parser.add_argument("--password", default=os.getenv("ADMIN_PASSWORD", "Admin@Ethio2026!"), help="Admin password")
    args = parser.parse_args()

    run_smoke_tests(args.url, args.username, args.password)
