"""
Seed master data (Sites and Work Types) for EthioWorkforce
Run: python scripts/seed_master_data.py
"""

import sys
from pathlib import Path
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.models.site import Site
from app.models.work_type import WorkType, PaymentMode, TaxRule
from app.core.database import SessionLocal
from sqlalchemy import select


def seed_master_data():
    """Seed sites and work types"""
    
    db = SessionLocal()
    
    try:
        print("🌱 Seeding master data for EthioWorkforce...")
        print("=" * 50)
        
        # Create Sites
        print("\n📍 Creating Sites...")
        sites_data = [
            {
                "name": "Bole Construction Site",
                "code": "BOLE-001",
                "description": "Main construction site with 200+ workers",
                "location_address": "Bole, Addis Ababa",
                "latitude": 8.9806,
                "longitude": 38.7578,
                "is_active": True
            },
            {
                "name": "Adama Factory",
                "code": "ADAMA-FAC",
                "description": "Manufacturing facility - 3 shifts",
                "location_address": "Adama, Oromia",
                "latitude": 8.5400,
                "longitude": 39.2675,
                "is_active": True
            },
            {
                "name": "Head Office",
                "code": "HQ-AA",
                "description": "Administrative headquarters",
                "location_address": "Megenagna, Addis Ababa",
                "latitude": 9.0192,
                "longitude": 38.7525,
                "is_active": True
            },
            {
                "name": "Bahir Dar Branch",
                "code": "BHR-001",
                "description": "Regional office and warehouse",
                "location_address": "Bahir Dar, Amhara",
                "latitude": 11.5936,
                "longitude": 37.3903,
                "is_active": True
            }
        ]
        
        sites_created = 0
        for site_data in sites_data:
            result = db.execute(select(Site).where(Site.code == site_data["code"]))
            existing = result.scalar_one_or_none()
            
            if not existing:
                site = Site(**site_data)
                db.add(site)
                sites_created += 1
                print(f"  ✅ Created: {site_data['name']}")
            else:
                print(f"  ⏭️  Exists: {site_data['name']}")
        
        db.commit()
        print(f"\n✅ Sites: {sites_created} created")
        
        # Create Work Types
        print("\n💼 Creating Work Types...")
        work_types_data = [
            {
                "name": "Daily Laborer",
                "code": "LABOR-DAY",
                "description": "General construction laborer - daily rate",
                "payment_mode": PaymentMode.DAILY_RATE,
                "base_rate": 300.00,
                "tax_rule": TaxRule.DAILY_CASUAL,
                "pension_eligible": False,
                "overtime_eligible": True,
                "overtime_rate_per_hour": 56.25,
                "is_active": True
            },
            {
                "name": "Site Engineer",
                "code": "ENG-SITE",
                "description": "Professional site engineer - monthly salary",
                "payment_mode": PaymentMode.MONTHLY_SALARY,
                "base_rate": 20000.00,
                "tax_rule": TaxRule.STANDARD_EMPLOYEE,
                "pension_eligible": True,
                "employee_pension_rate": 0.07,
                "employer_pension_rate": 0.11,
                "overtime_eligible": True,
                "overtime_rate_per_hour": 142.00,
                "is_active": True
            },
            {
                "name": "Machine Operator",
                "code": "MACH-OP",
                "description": "Heavy machinery operator - monthly salary",
                "payment_mode": PaymentMode.MONTHLY_SALARY,
                "base_rate": 12000.00,
                "tax_rule": TaxRule.STANDARD_EMPLOYEE,
                "pension_eligible": True,
                "employee_pension_rate": 0.07,
                "employer_pension_rate": 0.11,
                "overtime_eligible": True,
                "overtime_rate_per_hour": 102.00,
                "is_active": True
            },
            {
                "name": "Security Guard",
                "code": "SEC-GRD",
                "description": "Site security personnel - monthly salary",
                "payment_mode": PaymentMode.MONTHLY_SALARY,
                "base_rate": 5000.00,
                "tax_rule": TaxRule.STANDARD_EMPLOYEE,
                "pension_eligible": True,
                "employee_pension_rate": 0.07,
                "employer_pension_rate": 0.11,
                "overtime_eligible": False,
                "is_active": True
            },
            {
                "name": "Mason",
                "code": "MASON",
                "description": "Skilled masonry worker - daily rate",
                "payment_mode": PaymentMode.DAILY_RATE,
                "base_rate": 500.00,
                "tax_rule": TaxRule.DAILY_CASUAL,
                "pension_eligible": False,
                "overtime_eligible": True,
                "overtime_rate_per_hour": 93.75,
                "is_active": True
            },
            {
                "name": "Electrician",
                "code": "ELEC",
                "description": "Licensed electrician - hourly rate",
                "payment_mode": PaymentMode.HOURLY_RATE,
                "base_rate": 150.00,
                "tax_rule": TaxRule.STANDARD_EMPLOYEE,
                "pension_eligible": True,
                "employee_pension_rate": 0.07,
                "employer_pension_rate": 0.11,
                "overtime_eligible": True,
                "overtime_rate_per_hour": 225.00,
                "is_active": True
            },
            {
                "name": "Plumber",
                "code": "PLUMB",
                "description": "Professional plumber - hourly rate",
                "payment_mode": PaymentMode.HOURLY_RATE,
                "base_rate": 120.00,
                "tax_rule": TaxRule.STANDARD_EMPLOYEE,
                "pension_eligible": True,
                "employee_pension_rate": 0.07,
                "employer_pension_rate": 0.11,
                "overtime_eligible": True,
                "overtime_rate_per_hour": 180.00,
                "is_active": True
            },
            {
                "name": "Cleaner",
                "code": "CLEAN",
                "description": "Janitorial services - daily rate",
                "payment_mode": PaymentMode.DAILY_RATE,
                "base_rate": 150.00,
                "tax_rule": TaxRule.DAILY_CASUAL,
                "pension_eligible": False,
                "overtime_eligible": False,
                "is_active": True
            }
        ]
        
        wt_created = 0
        for wt_data in work_types_data:
            result = db.execute(select(WorkType).where(WorkType.code == wt_data["code"]))
            existing = result.scalar_one_or_none()
            
            if not existing:
                work_type = WorkType(**wt_data)
                db.add(work_type)
                wt_created += 1
                print(f"  ✅ Created: {wt_data['name']} ({wt_data['payment_mode'].value}, {wt_data['base_rate']} ETB)")
            else:
                print(f"  ⏭️  Exists: {wt_data['name']}")
        
        db.commit()
        print(f"\n✅ Work Types: {wt_created} created")
        
        print("\n" + "=" * 50)
        print("✅ Master data seeded successfully!")
        print("\n📊 Summary:")
        total_sites = db.execute(select(Site)).scalars().all()
        total_wt = db.execute(select(WorkType)).scalars().all()
        print(f"  - Total Sites: {len(total_sites)}")
        print(f"  - Total Work Types: {len(total_wt)}")
        print("=" * 50)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_master_data()
