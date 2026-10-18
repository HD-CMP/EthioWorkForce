"""add payment period to work types

Revision ID: 007_work_type_period
Revises: 006_payment_period_days
Create Date: 2026-01-26

"""
from alembic import op
import sqlalchemy as sa

revision = '007_work_type_period'
down_revision = '006_payment_period_days'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('work_types', sa.Column('payment_period_days', sa.Integer(), nullable=True))


def downgrade() -> None:
    op.drop_column('work_types', 'payment_period_days')
