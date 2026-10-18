"""add work place to workers

Revision ID: 020_work_place_to_workers
Revises: 019_user_work_place_assignments
Create Date: 2026-02-04 08:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = '020_work_place_to_workers'
down_revision = '019_user_work_place_assignments'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('workers', sa.Column('work_place_id', sa.Integer(), nullable=True))
    op.create_foreign_key('fk_workers_work_place_id', 'workers', 'work_places', ['work_place_id'], ['id'])
    op.create_index(op.f('ix_workers_work_place_id'), 'workers', ['work_place_id'], unique=False)


def downgrade():
    op.drop_index(op.f('ix_workers_work_place_id'), table_name='workers')
    op.drop_constraint('fk_workers_work_place_id', 'workers', type_='foreignkey')
    op.drop_column('workers', 'work_place_id')
