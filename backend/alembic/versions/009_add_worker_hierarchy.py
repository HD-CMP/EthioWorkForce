"""add worker hierarchy with supervisor

Revision ID: 009_worker_hierarchy
Revises: 008_remove_payment
Create Date: 2026-01-26

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = '009_worker_hierarchy'
down_revision = '008_remove_payment'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('workers')]
    
    if 'supervisor_id' not in columns:
        op.add_column('workers', sa.Column('supervisor_id', sa.Integer(), nullable=True))
        op.create_foreign_key(
            'fk_workers_supervisor_id',
            'workers', 'workers',
            ['supervisor_id'], ['id'],
            ondelete='SET NULL'
        )
        op.create_index('ix_workers_supervisor_id', 'workers', ['supervisor_id'])


def downgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    
    foreign_keys = [fk['name'] for fk in inspector.get_foreign_keys('workers')]
    if 'fk_workers_supervisor_id' in foreign_keys:
        op.drop_constraint('fk_workers_supervisor_id', 'workers', type_='foreignkey')
    
    indexes = [idx['name'] for idx in inspector.get_indexes('workers')]
    if 'ix_workers_supervisor_id' in indexes:
        op.drop_index('ix_workers_supervisor_id', 'workers')
    
    columns = [col['name'] for col in inspector.get_columns('workers')]
    if 'supervisor_id' in columns:
        op.drop_column('workers', 'supervisor_id')
