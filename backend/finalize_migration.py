#!/usr/bin/env python3
"""
Finalize migration by updating Alembic version table
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
        # Verify the constraint exists
        constraints = inspector.get_unique_constraints('workers')
        
        has_correct_constraint = any(
            c['name'] == 'uq_worker_employee_id_site_work_type' and
            set(c['column_names']) == {'employee_id', 'site_id', 'work_type_id'}
            for c in constraints
        )
        
        if not has_correct_constraint:
            logger.error("✗ Required constraint 'uq_worker_employee_id_site_work_type' not found!")
            logger.error("Run: python apply_employee_id_constraint.py")
            return
        
        logger.success("✓ Constraint verified: uq_worker_employee_id_site_work_type exists")
        
        # Get current version
        result = conn.execute(text("SELECT version_num FROM alembic_version"))
        current_version = result.scalar()
        
        logger.info(f"Current Alembic version: {current_version}")
        
        if current_version != '017_employee_id_work_type':
            logger.info("Updating Alembic version to 017_employee_id_work_type...")
            conn.execute(text("UPDATE alembic_version SET version_num = '017_employee_id_work_type'"))
            logger.success("✓ Alembic version updated to 017")
        else:
            logger.success("✓ Alembic version already at 017")
        
        logger.success("\n" + "="*60)
        logger.success("✅ MIGRATION COMPLETE!")
        logger.success("="*60)
        logger.info("\nEmployee ID Constraint Details:")
        logger.info("  - Unique per: (employee_id, site_id, work_type_id)")
        logger.info("  - Allows same employee_id across different sites")
        logger.info("  - Allows same employee_id across different work types")
        logger.info("  - Prevents duplicates within same site+work_type")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
