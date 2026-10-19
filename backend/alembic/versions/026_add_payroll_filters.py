"""add work_type_id and work_place_id to payrolls

Revision ID: 026_add_payroll_filters
Revises: 1a6043b6282c
Create Date: 2026-10-19 12:46:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = '026_add_payroll_filters'
down_revision = '1a6043b6282c'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    existing_columns = [col['name'] for col in inspector.get_columns('payrolls')]

    if 'work_type_id' not in existing_columns:
        op.add_column('payrolls', sa.Column('work_type_id', sa.Integer(), sa.ForeignKey('work_types.id'), nullable=True))

    if 'work_place_id' not in existing_columns:
        op.add_column('payrolls', sa.Column('work_place_id', sa.Integer(), sa.ForeignKey('work_places.id'), nullable=True))


def downgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    existing_columns = [col['name'] for col in inspector.get_columns('payrolls')]

    if 'work_place_id' in existing_columns:
        op.drop_column('payrolls', 'work_place_id')

    if 'work_type_id' in existing_columns:
        op.drop_column('payrolls', 'work_type_id')
