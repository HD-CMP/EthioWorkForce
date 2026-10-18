"""add payment period to payroll items

Revision ID: 018_payment_period_payroll_items
Revises: 017_employee_id_work_type
Create Date: 2026-02-02 18:50:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = '018_payment_period_payroll_items'
down_revision = '017_employee_id_work_type'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('payroll_items', sa.Column('payment_period_start', sa.Date(), nullable=True))
    op.add_column('payroll_items', sa.Column('payment_period_end', sa.Date(), nullable=True))
    op.add_column('payroll_items', sa.Column('payment_period_days', sa.Integer(), nullable=True))
    op.add_column('payroll_items', sa.Column('is_prorated', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('payroll_items', sa.Column('payment_period_type', sa.String(50), nullable=True))


def downgrade():
    op.drop_column('payroll_items', 'payment_period_type')
    op.drop_column('payroll_items', 'is_prorated')
    op.drop_column('payroll_items', 'payment_period_days')
    op.drop_column('payroll_items', 'payment_period_end')
    op.drop_column('payroll_items', 'payment_period_start')
