"""add allocated overtime to payroll items

Revision ID: 004_allocated_overtime
Revises: 003_worker_overtime
Create Date: 2026-01-25

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '004_allocated_overtime'
down_revision = '003_worker_overtime'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('payroll_items', sa.Column('allocated_overtime_pay', sa.Numeric(precision=12, scale=2), nullable=False, server_default='0'))


def downgrade() -> None:
    op.drop_column('payroll_items', 'allocated_overtime_pay')
