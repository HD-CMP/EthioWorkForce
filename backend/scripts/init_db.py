import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import create_engine
from loguru import logger

from app.core.config import settings
from app.core.database import Base
from app.models import *
from app.core.security import get_password_hash
from app.models.user import User, UserRole
from app.models.site import Site
from app.models.work_type import WorkType, PaymentMode, TaxRule
from app.models.user_site_assignment import UserSiteAssignment
from decimal import Decimal


def init_database():
    logger.info("Initializing database...")
    
    engine = create_engine(settings.database_url_str)
    
    Base.metadata.drop_all(bind=engine)
    logger.info("Dropped all tables")
    
    Base.metadata.create_all(bind=engine)
    logger.info("Created all tables")
    
    from sqlalchemy.orm import sessionmaker
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    
    try:
        admin_user = User(
            username="admin",
            email="admin@ethioworkforce.com",
            full_name="System Administrator",
            hashed_password=get_password_hash("admin123"),
            role=UserRole.SUPER_ADMIN,
            is_active=True,
            is_verified=True,
        )
        db.add(admin_user)
        db.flush()
        logger.info("Created SUPER_ADMIN user")
        
        site_admin_user = User(
            username="siteadmin",
            email="siteadmin@ethioworkforce.com",
            full_name="Site Administrator",
            hashed_password=get_password_hash("siteadmin123"),
            role=UserRole.SITE_ADMIN,
            is_active=True,
            is_verified=True,
        )
        db.add(site_admin_user)
        db.flush()
        logger.info("Created SITE_ADMIN user")
        
        admin_manager = User(
            username="adminuser",
            email="adminuser@ethioworkforce.com",
            full_name="Admin Manager",
            hashed_password=get_password_hash("admin123"),
            role=UserRole.ADMIN,
            is_active=True,
            is_verified=True,
        )
        db.add(admin_manager)
        db.flush()
        logger.info("Created ADMIN user")
        
        site1 = Site(
            name="Bole Construction Site",
            code="SITE-001",
            description="Main construction site in Bole",
            location_address="Bole, Addis Ababa",
            is_active=True,
        )
        db.add(site1)
        db.flush()
        logger.info("Created Bole Construction site")
        
        site2 = Site(
            name="Piassa Development Site",
            code="SITE-002",
            description="Development site in Piassa",
            location_address="Piassa, Addis Ababa",
            is_active=True,
        )
        db.add(site2)
        db.flush()
        logger.info("Created Piassa Development site")
        
        site_assignment1 = UserSiteAssignment(
            user_id=site_admin_user.id,
            site_id=site1.id,
            is_primary=True
        )
        db.add(site_assignment1)
        
        site_assignment2 = UserSiteAssignment(
            user_id=admin_manager.id,
            site_id=site1.id,
            is_primary=True
        )
        db.add(site_assignment2)
        
        site_assignment3 = UserSiteAssignment(
            user_id=admin_manager.id,
            site_id=site2.id,
            is_primary=False
        )
        db.add(site_assignment3)
        logger.info("Created site assignments")
        
        db.commit()
        logger.info("Initial setup completed. Run 'python scripts/seed_master_data.py' to add work types.")
        logger.info("Database initialization completed successfully!")
        
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    init_database()
