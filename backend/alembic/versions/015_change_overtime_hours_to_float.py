"""change overtime_hours to float

Revision ID: 015_overtime_float
Revises: 014_work_type_period_start
Create Date: 2026-01-29

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = '015_overtime_float'
down_revision = '014_work_type_period_start'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    
    # Change overtime_hours in attendances table from Integer to Float
    op.alter_column('attendances', 'overtime_hours',
                    existing_type=sa.Integer(),
                    type_=sa.Float(),
                    existing_nullable=False,
                    existing_server_default=sa.text('0'))
    
    # Change overtime_hours in payroll_items table from Integer to Float
    op.alter_column('payroll_items', 'overtime_hours',
                    existing_type=sa.Integer(),
                    type_=sa.Float(),
                    existing_nullable=False,
                    existing_server_default=sa.text('0'))


def downgrade() -> None:
    # Revert overtime_hours in payroll_items table back to Integer
    op.alter_column('payroll_items', 'overtime_hours',
                    existing_type=sa.Float(),
                    type_=sa.Integer(),
                    existing_nullable=False,
                    existing_server_default=sa.text('0'))
    
    # Revert overtime_hours in attendances table back to Integer
    op.alter_column('attendances', 'overtime_hours',
                    existing_type=sa.Float(),
                    type_=sa.Integer(),
                    existing_nullable=False,
                    existing_server_default=sa.text('0'))
