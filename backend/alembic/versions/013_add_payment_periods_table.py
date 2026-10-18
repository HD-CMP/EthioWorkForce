"""Add payment_periods table

Revision ID: 013_payment_periods
Revises: 012_readd_payment_period
Create Date: 2026-01-27

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from sqlalchemy import inspect

revision = '013_payment_periods'
down_revision = '012_readd_payment_period'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    tables = inspector.get_table_names()
    
    if 'payment_periods' not in tables:
        # Create PeriodStatus enum if it doesn't exist
        conn.execute(sa.text("""
            DO $$ BEGIN
                CREATE TYPE periodstatus AS ENUM ('active', 'closed', 'locked');
            EXCEPTION
                WHEN duplicate_object THEN null;
            END $$;
        """))
        
        # Create table using raw SQL to avoid SQLAlchemy enum issues
        conn.execute(sa.text("""
            CREATE TABLE payment_periods (
                id SERIAL PRIMARY KEY,
                site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
                period_start DATE NOT NULL,
                period_end DATE NOT NULL,
                period_days INTEGER NOT NULL,
                status periodstatus NOT NULL DEFAULT 'active',
                is_current BOOLEAN NOT NULL DEFAULT false,
                ethiopian_start_year INTEGER,
                ethiopian_start_month INTEGER,
                ethiopian_start_day INTEGER,
                ethiopian_end_year INTEGER,
                ethiopian_end_month INTEGER,
                ethiopian_end_day INTEGER,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """))
        
        conn.execute(sa.text("CREATE INDEX IF NOT EXISTS ix_payment_periods_site_id ON payment_periods(site_id)"))
        conn.execute(sa.text("CREATE INDEX IF NOT EXISTS ix_payment_periods_period_start ON payment_periods(period_start)"))
        conn.execute(sa.text("CREATE INDEX IF NOT EXISTS ix_payment_periods_period_end ON payment_periods(period_end)"))


def downgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    tables = inspector.get_table_names()
    
    if 'payment_periods' in tables:
        op.drop_table('payment_periods')
    
    # Drop enum type if it exists
    conn.execute(sa.text("DROP TYPE IF EXISTS periodstatus CASCADE"))
