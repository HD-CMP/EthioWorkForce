"""
Production-safe Cloud Database Initializer & Seeder for EthioWorkforce.
Safely creates tables via Alembic migrations and seeds default admin and master data.
IDEMPOTENT: Safe to run on every deployment without data loss.

Usage:
  python scripts/init_cloud_db.py
"""

import sys
import os
from pathlib import Path
from decimal import Decimal

# Ensure backend root is on sys.path
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import sessionmaker
from loguru import logger

from app.core.config import settings
from app.core.database import Base
from app.core.security import get_password_hash
from app.models.user import User, UserRole
from app.models.site import Site
from app.models.work_place import WorkPlace
from app.models.work_type import WorkType, PaymentMode, TaxRule
from app.models.user_site_assignment import UserSiteAssignment
import app.models


def run_alembic_migrations():
    """Execute Alembic migrations programmatically to bring schema to head."""
    logger.info("Running Alembic migrations to head...")
    try:
        from alembic.config import Config
        from alembic import command
        
        backend_dir = Path(__file__).parent.parent
        alembic_ini = backend_dir / "alembic.ini"
        
        if alembic_ini.exists():
            alembic_cfg = Config(str(alembic_ini))
            alembic_cfg.set_main_option("script_location", str(backend_dir / "alembic"))
            alembic_cfg.set_main_option("sqlalchemy.url", settings.database_url_str)
            command.upgrade(alembic_cfg, "head")
            logger.info("Alembic migrations completed successfully.")
        else:
            logger.warning("alembic.ini not found, creating all tables directly from metadata...")
            engine = create_engine(settings.database_url_str)
            Base.metadata.create_all(bind=engine)
    except Exception as e:
        logger.warning(f"Alembic auto-migration encountered warning/notice: {e}")
        logger.info("Ensuring all tables exist via SQLAlchemy metadata...")
        engine = create_engine(settings.database_url_str)
        Base.metadata.create_all(bind=engine)


def seed_cloud_database():
    """Seed initial super admin, sites, and standard work types if empty."""
    logger.info(f"Connecting to database: {settings.database_url_str.split('@')[-1] if '@' in settings.database_url_str else 'local'}...")
    engine = create_engine(settings.database_url_str)
    Session = sessionmaker(bind=engine)
    db = Session()

    try:
        # 1. Super Admin User
        admin_pass = os.getenv("INITIAL_ADMIN_PASSWORD", "Admin@Ethio2026!")
        admin_user = db.query(User).filter(
            (User.username == "admin") | (User.role == UserRole.SUPER_ADMIN)
        ).first()

        if not admin_user:
            logger.info("Creating default Super Admin user...")
            admin_user = User(
                username="admin",
                email="admin@ethioworkforce.com",
                full_name="System Administrator",
                hashed_password=get_password_hash(admin_pass),
                role=UserRole.SUPER_ADMIN,
                is_active=True,
                is_verified=True,
            )
            db.add(admin_user)
            db.flush()
            logger.info(f"Super Admin created: username='admin', password='{admin_pass}'")
        else:
            logger.info(f"Super Admin already exists (id={admin_user.id}, username='{admin_user.username}'). Skipping.")

        # 2. Master Sites
        site_count = db.query(Site).count()
        if site_count == 0:
            logger.info("Seeding default construction & operational sites...")
            default_sites = [
                Site(
                    name="Bole Construction Site",
                    code="SITE-001",
                    description="Main commercial building construction project",
                    location_address="Bole, Addis Ababa",
                    latitude=8.9806,
                    longitude=38.7578,
                    is_active=True,
                ),
                Site(
                    name="Adama Industrial Facility",
                    code="SITE-002",
                    description="Manufacturing and processing plant",
                    location_address="Adama, Oromia",
                    latitude=8.5400,
                    longitude=39.2675,
                    is_active=True,
                ),
                Site(
                    name="Headquarters",
                    code="SITE-HQ",
                    description="Central administrative offices",
                    location_address="Megenagna, Addis Ababa",
                    latitude=9.0192,
                    longitude=38.7525,
                    is_active=True,
                ),
            ]
            db.add_all(default_sites)
            db.flush()
            logger.info(f"Seeded {len(default_sites)} default sites.")

            # Assign admin to primary site
            primary_site = default_sites[0]
            existing_assignment = db.query(UserSiteAssignment).filter(
                UserSiteAssignment.user_id == admin_user.id,
                UserSiteAssignment.site_id == primary_site.id
            ).first()
            if not existing_assignment:
                db.add(UserSiteAssignment(
                    user_id=admin_user.id,
                    site_id=primary_site.id,
                    is_primary=True
                ))
                db.flush()
        else:
            logger.info(f"Found {site_count} existing sites. Skipping site seed.")

        # 3. Standard Work Types (Ethiopian Labor Compliance)
        work_type_count = db.query(WorkType).count()
        if work_type_count == 0:
            logger.info("Seeding standard Ethiopian labor work types...")
            default_work_types = [
                WorkType(
                    name="Daily Casual Laborer",
                    code="WT-CASUAL",
                    description="Daily casual worker paid in cash daily with zero statutory deductions",
                    payment_mode=PaymentMode.DAILY,
                    tax_rule=TaxRule.NONE,
                    has_pension=False,
                    payment_period_days=1,
                    daily_rate=Decimal("350.00"),
                    hourly_rate=Decimal("43.75"),
                    is_active=True,
                ),
                WorkType(
                    name="Mason / Skilled Artisan",
                    code="WT-MASON",
                    description="Skilled construction artisan paid on bi-weekly or monthly schedule",
                    payment_mode=PaymentMode.MONTHLY,
                    tax_rule=TaxRule.STANDARD,
                    has_pension=True,
                    payment_period_days=30,
                    daily_rate=Decimal("600.00"),
                    hourly_rate=Decimal("75.00"),
                    base_salary=Decimal("15000.00"),
                    is_active=True,
                ),
                WorkType(
                    name="Site Supervisor / Engineer",
                    code="WT-SUPERVISOR",
                    description="Site manager and technical engineer paid monthly via bank transfer",
                    payment_mode=PaymentMode.MONTHLY,
                    tax_rule=TaxRule.STANDARD,
                    has_pension=True,
                    payment_period_days=30,
                    base_salary=Decimal("28000.00"),
                    daily_rate=Decimal("1076.92"),
                    hourly_rate=Decimal("134.62"),
                    is_active=True,
                ),
                WorkType(
                    name="Security Guard",
                    code="WT-SECURITY",
                    description="Facility security officer on shift rotations",
                    payment_mode=PaymentMode.MONTHLY,
                    tax_rule=TaxRule.STANDARD,
                    has_pension=True,
                    payment_period_days=30,
                    base_salary=Decimal("8000.00"),
                    daily_rate=Decimal("307.69"),
                    hourly_rate=Decimal("38.46"),
                    is_active=True,
                ),
            ]
            db.add_all(default_work_types)
            db.flush()
            logger.info(f"Seeded {len(default_work_types)} standard work types.")
        else:
            logger.info(f"Found {work_type_count} existing work types. Skipping work type seed.")

        db.commit()
        logger.info("Cloud database initialization and seeding completed successfully!")
        print("\n" + "=" * 60)
        print("[SUCCESS] EthioWorkforce Cloud Database Ready!")
        print(f"[*] Admin Username: admin")
        print(f"[*] Admin Password: {admin_pass}")
        print("=" * 60 + "\n")

    except Exception as e:
        db.rollback()
        logger.error(f"Error during cloud database initialization: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    run_alembic_migrations()
    seed_cloud_database()
