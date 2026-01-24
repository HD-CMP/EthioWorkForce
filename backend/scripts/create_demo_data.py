"""
Create demo data for EthioWorkforce
Run: python scripts/create_demo_data.py
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.models import Site, WorkType, Worker, User, Attendance
from app.database import SessionLocal
from sqlalchemy import select


async def create_demo_data():
    """Create sample data for demo purposes"""
    
    db = SessionLocal()
    
    try:
        print("🚀 Creating demo data for EthioWorkforce...")
        print("=" * 50)
        
        # Get admin user
        result = db.execute(select(User).where(User.username == "admin"))
        admin_user = result.scalar_one_or_none()
        
        if not admin_user:
            print("❌ Admin user not found. Run init_db.py first!")
            return
        
        # Create Sites
        print("\n📍 Creating Sites...")
        sites_data = [
            {
                "name": "Bole Construction Site",
                "location": "Bole, Addis Ababa",
                "code": "BOLE-001",
                "description": "Main construction site with 200+ workers"
            },
            {
                "name": "Adama Factory",
                "location": "Adama, Oromia",
                "code": "ADAMA-FAC",
                "description": "Manufacturing facility - 3 shifts"
            },
            {
                "name": "Head Office",
                "location": "Megenagna, Addis Ababa",
                "code": "HQ-AA",
                "description": "Administrative headquarters"
            }
        ]
        
        sites = []
        for site_data in sites_data:
            # Check if exists
            result = db.execute(select(Site).where(Site.code == site_data["code"]))
            existing_site = result.scalar_one_or_none()
            
            if not existing_site:
                site = Site(**site_data, created_by_id=admin_user.id)
                db.add(site)
                sites.append(site)
                print(f"  ✅ Created: {site_data['name']}")
            else:
                sites.append(existing_site)
                print(f"  ⏭️  Exists: {site_data['name']}")
        
        db.commit()
        
        # Create Work Types
        print("\n💼 Creating Work Types...")
        work_types_data = [
            {
                "name": "Daily Laborer",
                "code": "LABOR-DAY",
                "payment_mode": "daily",
                "daily_rate": 300.00,
                "is_taxable": False,  # No tax for daily workers
                "apply_pension": False,
                "overtime_eligible": True,
                "overtime_rate": 1.5
            },
            {
                "name": "Site Engineer",
                "code": "ENG-SITE",
                "payment_mode": "monthly",
                "monthly_salary": 20000.00,
                "is_taxable": True,  # Apply ERCA tax
                "apply_pension": True,  # 7% employee + 11% employer
                "overtime_eligible": True,
                "overtime_rate": 1.25
            },
            {
                "name": "Machine Operator",
                "code": "MACH-OP",
                "payment_mode": "monthly",
                "monthly_salary": 12000.00,
                "is_taxable": True,
                "apply_pension": True,
                "overtime_eligible": True,
                "overtime_rate": 1.5
            },
            {
                "name": "Security Guard",
                "code": "SEC-GRD",
                "payment_mode": "monthly",
                "monthly_salary": 5000.00,
                "is_taxable": True,
                "apply_pension": True,
                "overtime_eligible": False
            },
            {
                "name": "Mason",
                "code": "MASON",
                "payment_mode": "daily",
                "daily_rate": 500.00,
                "is_taxable": False,
                "apply_pension": False,
                "overtime_eligible": True,
                "overtime_rate": 1.5
            }
        ]
        
        work_types = []
        for wt_data in work_types_data:
            result = db.execute(select(WorkType).where(WorkType.code == wt_data["code"]))
            existing_wt = result.scalar_one_or_none()
            
            if not existing_wt:
                work_type = WorkType(**wt_data, created_by_id=admin_user.id)
                db.add(work_type)
                work_types.append(work_type)
                print(f"  ✅ Created: {wt_data['name']} ({wt_data['payment_mode']})")
            else:
                work_types.append(existing_wt)
                print(f"  ⏭️  Exists: {wt_data['name']}")
        
        db.commit()
        
        # Create Workers
        print("\n👷 Creating Workers...")
        workers_data = [
            # Bole Site - Daily Laborers
            {
                "full_name": "Alemayehu Tadesse",
                "phone": "+251911234567",
                "site_id": sites[0].id,
                "work_type_id": work_types[0].id,  # Daily Laborer
                "employee_id": "BL-001"
            },
            {
                "full_name": "Birtukan Kebede",
                "phone": "+251922345678",
                "site_id": sites[0].id,
                "work_type_id": work_types[0].id,
                "employee_id": "BL-002"
            },
            {
                "full_name": "Chaltu Gemechu",
                "phone": "+251933456789",
                "site_id": sites[0].id,
                "work_type_id": work_types[4].id,  # Mason
                "employee_id": "BL-003"
            },
            # Bole Site - Engineers
            {
                "full_name": "Dr. Dawit Haile",
                "phone": "+251944567890",
                "site_id": sites[0].id,
                "work_type_id": work_types[1].id,  # Site Engineer
                "employee_id": "ENG-001"
            },
            {
                "full_name": "Emebet Solomon",
                "phone": "+251955678901",
                "site_id": sites[0].id,
                "work_type_id": work_types[1].id,
                "employee_id": "ENG-002"
            },
            # Adama Factory
            {
                "full_name": "Fikadu Abera",
                "phone": "+251966789012",
                "site_id": sites[1].id,
                "work_type_id": work_types[2].id,  # Machine Operator
                "employee_id": "FAC-001"
            },
            {
                "full_name": "Genet Mamo",
                "phone": "+251977890123",
                "site_id": sites[1].id,
                "work_type_id": work_types[2].id,
                "employee_id": "FAC-002"
            },
            # Head Office
            {
                "full_name": "Habtamu Negash",
                "phone": "+251988901234",
                "site_id": sites[2].id,
                "work_type_id": work_types[3].id,  # Security Guard
                "employee_id": "HQ-SEC-001"
            }
        ]
        
        workers = []
        for worker_data in workers_data:
            result = db.execute(select(Worker).where(Worker.employee_id == worker_data["employee_id"]))
            existing_worker = result.scalar_one_or_none()
            
            if not existing_worker:
                worker = Worker(
                    **worker_data,
                    created_by_id=admin_user.id,
                    is_active=True,
                    use_ethiopian_calendar=True
                )
                db.add(worker)
                workers.append(worker)
                print(f"  ✅ Created: {worker_data['full_name']} ({worker_data['employee_id']})")
            else:
                workers.append(existing_worker)
                print(f"  ⏭️  Exists: {worker_data['full_name']}")
        
        db.commit()
        
        # Create Attendance Records (last 7 days)
        print("\n📅 Creating Attendance Records...")
        today = datetime.now().date()
        
        attendance_count = 0
        for worker in workers:
            for day_offset in range(7):
                date = today - timedelta(days=day_offset)
                
                # Skip weekends for some variety
                if date.weekday() == 6:  # Sunday
                    continue
                
                result = db.execute(
                    select(Attendance).where(
                        Attendance.worker_id == worker.id,
                        Attendance.date == date
                    )
                )
                existing_attendance = result.scalar_one_or_none()
                
                if not existing_attendance:
                    attendance = Attendance(
                        worker_id=worker.id,
                        site_id=worker.site_id,
                        date=date,
                        status="present",
                        verified_by_id=admin_user.id,
                        verified_at=datetime.now(),
                        created_by_id=admin_user.id
                    )
                    db.add(attendance)
                    attendance_count += 1
        
        db.commit()
        print(f"  ✅ Created {attendance_count} attendance records")
        
        print("\n" + "=" * 50)
        print("✅ Demo data created successfully!")
        print("\n📊 Summary:")
        print(f"  - Sites: {len(sites)}")
        print(f"  - Work Types: {len(work_types)}")
        print(f"  - Workers: {len(workers)}")
        print(f"  - Attendance Records: {attendance_count}")
        print("\n💡 Login with:")
        print("  Username: admin")
        print("  Password: admin123")
        print("=" * 50)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(create_demo_data())
