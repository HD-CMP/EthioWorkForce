#!/usr/bin/env python3
"""
Cleanup old employee_id constraint that only had 2 columns
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine, text, inspect
from app.core.config import settings
from loguru import logger

def main():
    engine = create_engine(settings.database_url_str)
    inspector = inspect(engine)
    
    with engine.begin() as conn:
        constraints = inspector.get_unique_constraints('workers')
        
        logger.info("Current unique constraints on workers table:")
        for const in constraints:
            logger.info(f"  - {const['name']}: columns={const['column_names']}")
        
        # Check for old 2-column constraint
        has_old_constraint = any(
            c['name'] == 'uq_worker_employee_id_work_type' and 
            len(c['column_names']) == 2
            for c in constraints
        )
        
        # Check for new 3-column constraint
        has_new_constraint = any(
            c['name'] == 'uq_worker_employee_id_site_work_type' and
            len(c['column_names']) == 3
            for c in constraints
        )
        
        if not has_new_constraint:
            logger.error("✗ New 3-column constraint not found! Run apply_employee_id_constraint.py first.")
            return
        
        if has_old_constraint:
            logger.warning("\nFound old 2-column constraint. Dropping it...")
            conn.execute(text("ALTER TABLE workers DROP CONSTRAINT uq_worker_employee_id_work_type"))
            logger.success("✓ Dropped old constraint uq_worker_employee_id_work_type")
        else:
            logger.success("✓ Old constraint already removed")
        
        logger.success("\n" + "="*60)
        logger.success("Cleanup completed!")
        logger.success("Final constraint: uq_worker_employee_id_site_work_type")
        logger.success("Columns: employee_id, site_id, work_type_id")
        logger.success("="*60)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
