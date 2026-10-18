"""add payment_period_start_date to work_types

Revision ID: 014_work_type_period_start
Revises: 013_payment_periods
Create Date: 2026-01-29

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = '014_work_type_period_start'
down_revision = '013_payment_periods'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('work_types')]
    
    if 'payment_period_start_date' not in columns:
        op.add_column('work_types', sa.Column('payment_period_start_date', sa.Date(), nullable=True))


def downgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('work_types')]
    
    if 'payment_period_start_date' in columns:
        op.drop_column('work_types', 'payment_period_start_date')
