"""Re-add payment_period_days to workers

Revision ID: 012_readd_payment_period
Revises: 011_work_places
Create Date: 2026-01-27

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = '012_readd_payment_period'
down_revision = '011_work_places'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('workers')]
    
    if 'payment_period_days' not in columns:
        op.add_column('workers', sa.Column('payment_period_days', sa.Integer(), nullable=True, server_default='14'))


def downgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('workers')]
    
    if 'payment_period_days' in columns:
        op.drop_column('workers', 'payment_period_days')
