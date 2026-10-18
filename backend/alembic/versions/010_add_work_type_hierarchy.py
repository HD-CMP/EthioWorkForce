"""add work type hierarchy

Revision ID: 010_work_type_hierarchy
Revises: 009_worker_hierarchy
Create Date: 2026-01-26

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = '010_work_type_hierarchy'
down_revision = '009_worker_hierarchy'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('work_types')]
    
    if 'hierarchy_level' not in columns:
        op.add_column('work_types', sa.Column('hierarchy_level', sa.Integer(), nullable=False, server_default='5'))
    
    if 'parent_work_type_id' not in columns:
        op.add_column('work_types', sa.Column('parent_work_type_id', sa.Integer(), nullable=True))
    
    if 'can_manage_levels' not in columns:
        op.add_column('work_types', sa.Column('can_manage_levels', sa.String(50), nullable=True))
    
    if 'requires_supervisor' not in columns:
        op.add_column('work_types', sa.Column('requires_supervisor', sa.Boolean(), nullable=False, server_default='true'))
    
    if 'max_subordinates' not in columns:
        op.add_column('work_types', sa.Column('max_subordinates', sa.Integer(), nullable=True))
    
    conn.execute(sa.text("CREATE INDEX IF NOT EXISTS ix_work_types_hierarchy_level ON work_types(hierarchy_level)"))
    conn.execute(sa.text("CREATE INDEX IF NOT EXISTS ix_work_types_parent_work_type_id ON work_types(parent_work_type_id)"))


def downgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    
    indexes = [idx['name'] for idx in inspector.get_indexes('work_types')]
    if 'ix_work_types_parent_work_type_id' in indexes:
        op.drop_index('ix_work_types_parent_work_type_id', 'work_types')
    if 'ix_work_types_hierarchy_level' in indexes:
        op.drop_index('ix_work_types_hierarchy_level', 'work_types')
    
    columns = [col['name'] for col in inspector.get_columns('work_types')]
    
    if 'max_subordinates' in columns:
        op.drop_column('work_types', 'max_subordinates')
    if 'requires_supervisor' in columns:
        op.drop_column('work_types', 'requires_supervisor')
    if 'can_manage_levels' in columns:
        op.drop_column('work_types', 'can_manage_levels')
    if 'parent_work_type_id' in columns:
        op.drop_column('work_types', 'parent_work_type_id')
    if 'hierarchy_level' in columns:
        op.drop_column('work_types', 'hierarchy_level')
