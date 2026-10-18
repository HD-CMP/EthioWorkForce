"""
Clean up duplicate work types created by init_db.py
Run: python scripts/cleanup_duplicates.py
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.core.database import SessionLocal
from app.models.work_type import WorkType
from app.models.worker import Worker
from sqlalchemy import select

def cleanup_duplicates():
    db = SessionLocal()
    
    try:
        print("🧹 Cleaning up duplicate work types...")
        print("=" * 60)
        
        # Find old work types
        old_daily = db.execute(select(WorkType).where(WorkType.code == "DL-001")).scalar_one_or_none()
        old_engineer = db.execute(select(WorkType).where(WorkType.code == "ENG-001")).scalar_one_or_none()
        
        # Find new work types
        new_daily = db.execute(select(WorkType).where(WorkType.code == "LABOR-DAY")).scalar_one_or_none()
        new_engineer = db.execute(select(WorkType).where(WorkType.code == "ENG-SITE")).scalar_one_or_none()
        
        if old_daily and new_daily:
            print(f"\n📋 Found duplicate 'Daily Laborer':")
            print(f"  Old: ID={old_daily.id}, Code={old_daily.code}")
            print(f"  New: ID={new_daily.id}, Code={new_daily.code}")
            
            # Update workers
            workers_updated = db.execute(
                select(Worker).where(Worker.work_type_id == old_daily.id)
            ).scalars().all()
            
            for worker in workers_updated:
                worker.work_type_id = new_daily.id
                print(f"  ✅ Updated worker: {worker.full_name}")
            
            db.delete(old_daily)
            print(f"  🗑️  Deleted old work type: {old_daily.code}")
        else:
            print("\n✅ No duplicate 'Daily Laborer' found")
        
        if old_engineer and new_engineer:
            print(f"\n📋 Found duplicate 'Site Engineer':")
            print(f"  Old: ID={old_engineer.id}, Code={old_engineer.code}")
            print(f"  New: ID={new_engineer.id}, Code={new_engineer.code}")
            
            # Update workers
            workers_updated = db.execute(
                select(Worker).where(Worker.work_type_id == old_engineer.id)
            ).scalars().all()
            
            for worker in workers_updated:
                worker.work_type_id = new_engineer.id
                print(f"  ✅ Updated worker: {worker.full_name}")
            
            db.delete(old_engineer)
            print(f"  🗑️  Deleted old work type: {old_engineer.code}")
        else:
            print("\n✅ No duplicate 'Site Engineer' found")
        
        db.commit()
        
        print("\n" + "=" * 60)
        print("✅ Cleanup completed successfully!")
        
        # Show remaining work types
        print("\n📊 Current Work Types:")
        work_types = db.execute(select(WorkType).order_by(WorkType.name)).scalars().all()
        for wt in work_types:
            worker_count = db.execute(
                select(Worker).where(Worker.work_type_id == wt.id)
            ).scalars().all()
            print(f"  - {wt.name} ({wt.code}): {len(worker_count)} workers")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    cleanup_duplicates()
