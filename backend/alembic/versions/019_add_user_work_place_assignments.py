"""add user work place assignments

Revision ID: 019_user_work_place_assignments
Revises: 018_payment_period_payroll_items
Create Date: 2026-02-04 08:15:00.000000

"""
from alembic import op
import sqlalchemy as sa
from datetime import datetime


revision = '019_user_work_place_assignments'
down_revision = '018_payment_period_payroll_items'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'user_work_place_assignments',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('work_place_id', sa.Integer(), nullable=False),
        sa.Column('is_primary', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['work_place_id'], ['work_places.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_user_work_place_assignments_user_id'), 'user_work_place_assignments', ['user_id'], unique=False)
    op.create_index(op.f('ix_user_work_place_assignments_work_place_id'), 'user_work_place_assignments', ['work_place_id'], unique=False)


def downgrade():
    op.drop_index(op.f('ix_user_work_place_assignments_work_place_id'), table_name='user_work_place_assignments')
    op.drop_index(op.f('ix_user_work_place_assignments_user_id'), table_name='user_work_place_assignments')
    op.drop_table('user_work_place_assignments')
