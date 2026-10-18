"""add payment period days to workers

Revision ID: 006_payment_period_days
Revises: 005_overtime_rate
Create Date: 2026-01-26

"""
from alembic import op
import sqlalchemy as sa

revision = '006_payment_period_days'
down_revision = '005_overtime_rate'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('workers', sa.Column('payment_period_days', sa.Integer(), nullable=True))


def downgrade() -> None:
    op.drop_column('workers', 'payment_period_days')
