"""remove payment fields from workers

Revision ID: 008_remove_payment
Revises: 007_work_type_period
Create Date: 2026-01-26

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from sqlalchemy import inspect

revision = '008_remove_payment'
down_revision = '007_work_type_period'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('workers')]
    
    if 'payment_cycle' in columns:
        op.drop_column('workers', 'payment_cycle')
    
    if 'payment_period_days' in columns:
        op.drop_column('workers', 'payment_period_days')


def downgrade() -> None:
    op.add_column('workers', sa.Column('payment_period_days', sa.Integer(), nullable=True))
    op.add_column('workers', sa.Column('payment_cycle', 
        postgresql.ENUM('daily', 'weekly', 'bi_weekly', 'monthly', name='paymentcycle'), 
        nullable=False, 
        server_default='monthly'))
