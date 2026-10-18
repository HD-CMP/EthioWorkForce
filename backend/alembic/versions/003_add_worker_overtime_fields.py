"""add worker overtime fields

Revision ID: 003_worker_overtime
Revises: 002_hierarchical_permissions
Create Date: 2026-01-25

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '003_worker_overtime'
down_revision = '002_hierarchical_permissions'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('workers', sa.Column('overtime_hours', sa.Numeric(precision=6, scale=2), nullable=True, server_default='0'))
    op.add_column('workers', sa.Column('overtime_rate_per_hour', sa.Numeric(precision=10, scale=2), nullable=True, server_default='0'))


def downgrade() -> None:
    op.drop_column('workers', 'overtime_rate_per_hour')
    op.drop_column('workers', 'overtime_hours')
