"""change overtime multiplier to rate per hour

Revision ID: 005_overtime_rate
Revises: 004_allocated_overtime
Create Date: 2026-01-26

"""
from alembic import op
import sqlalchemy as sa

revision = '005_overtime_rate'
down_revision = '004_allocated_overtime'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_column('work_types', 'overtime_multiplier')
    op.add_column('work_types', sa.Column('overtime_rate_per_hour', sa.Numeric(precision=10, scale=2), nullable=True))


def downgrade() -> None:
    op.drop_column('work_types', 'overtime_rate_per_hour')
    op.add_column('work_types', sa.Column('overtime_multiplier', sa.Float(), nullable=True, server_default='1.5'))
