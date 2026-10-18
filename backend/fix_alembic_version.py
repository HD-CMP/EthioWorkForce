#!/usr/bin/env python3
"""
Fix Alembic version table if migration is stuck
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine, text
from app.core.config import settings
from loguru import logger

def main():
    engine = create_engine(settings.database_url_str)
    
    with engine.begin() as conn:
        # Check current alembic version
        result = conn.execute(text("SELECT version_num FROM alembic_version"))
        current_version = result.scalar()
        
        logger.info(f"Current Alembic version: {current_version}")
        
        if current_version == '017_employee_id_work_type':
            logger.warning("Database is marked as version 017, but migration might not be complete.")
            logger.info("Rolling back to 016 to allow re-running migration...")
            
            conn.execute(text("UPDATE alembic_version SET version_num = '016_overtime_verification'"))
            logger.success("✓ Rolled back to version 016_overtime_verification")
            logger.info("\nNow run: alembic upgrade head")
            
        elif current_version == '016_overtime_verification':
            logger.info("Database is at version 016. Ready to upgrade.")
            logger.info("Run: alembic upgrade head")
            
        else:
            logger.info(f"Database is at version: {current_version}")
            logger.info("Run: alembic upgrade head")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
