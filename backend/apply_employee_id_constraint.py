#!/usr/bin/env python3
"""
Manually apply employee_id constraint update
Run this if alembic upgrade head doesn't apply the migration
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
        # Check current indexes and constraints
        indexes = inspector.get_indexes('workers')
        constraints = inspector.get_unique_constraints('workers')
        
        logger.info("Current indexes on workers table:")
        for idx in indexes:
            logger.info(f"  - {idx['name']}: columns={idx['column_names']}, unique={idx.get('unique', False)}")
        
        logger.info("\nCurrent unique constraints on workers table:")
        for const in constraints:
            logger.info(f"  - {const['name']}: columns={const['column_names']}")
        
        # Check if new constraint already exists
        has_new_constraint = any(
            c['name'] == 'uq_worker_employee_id_site_work_type' 
            for c in constraints
        )
        
        if has_new_constraint:
            logger.success("✓ Constraint 'uq_worker_employee_id_site_work_type' already exists!")
            logger.info("Employee ID is already unique per site and work type.")
            return
        
        logger.info("\nApplying changes...")
        
        # Step 1: Check if old unique index exists
        has_unique_index = any(
            idx['name'] == 'ix_workers_employee_id' and idx.get('unique', False)
            for idx in indexes
        )
        
        if has_unique_index:
            logger.info("Dropping unique index ix_workers_employee_id...")
            conn.execute(text("DROP INDEX IF EXISTS ix_workers_employee_id"))
            logger.success("✓ Dropped unique index")
        
        # Step 2: Create non-unique index
        logger.info("Creating non-unique index ix_workers_employee_id...")
        conn.execute(text("""
            CREATE INDEX IF NOT EXISTS ix_workers_employee_id 
            ON workers (employee_id)
        """))
        logger.success("✓ Created non-unique index")
        
        # Step 3: Create composite unique constraint
        logger.info("Creating composite unique constraint...")
        conn.execute(text("""
            ALTER TABLE workers 
            ADD CONSTRAINT uq_worker_employee_id_site_work_type 
            UNIQUE (employee_id, site_id, work_type_id)
        """))
        logger.success("✓ Created constraint uq_worker_employee_id_site_work_type")
        
        logger.success("\n" + "="*60)
        logger.success("Migration completed successfully!")
        logger.success("Employee IDs are now unique per site and work type.")
        logger.success("="*60)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
