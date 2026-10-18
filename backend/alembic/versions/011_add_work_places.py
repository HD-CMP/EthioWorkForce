"""Add work_places table

Revision ID: 011_work_places
Revises: 010_work_type_hierarchy
Create Date: 2026-01-26

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = '011_work_places'
down_revision = '010_work_type_hierarchy'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    tables = inspector.get_table_names()
    
    if 'work_places' not in tables:
        op.create_table(
            'work_places',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('name', sa.String(255), nullable=False, index=True),
            sa.Column('code', sa.String(50), nullable=False, index=True),
            sa.Column('description', sa.String(1000), nullable=True),
            sa.Column('location_address', sa.String(500), nullable=True),
            sa.Column('latitude', sa.Float(), nullable=True),
            sa.Column('longitude', sa.Float(), nullable=True),
            sa.Column('parent_site_id', sa.Integer(), nullable=False),
            sa.Column('supervisor_id', sa.Integer(), nullable=True),
            sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
            sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
            sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
            sa.PrimaryKeyConstraint('id'),
            sa.ForeignKeyConstraint(['parent_site_id'], ['sites.id'], ondelete='CASCADE'),
            sa.ForeignKeyConstraint(['supervisor_id'], ['workers.id'], ondelete='SET NULL'),
        )
        
        conn.execute(sa.text("CREATE INDEX IF NOT EXISTS ix_work_places_parent_site_id ON work_places(parent_site_id)"))
        conn.execute(sa.text("CREATE INDEX IF NOT EXISTS ix_work_places_supervisor_id ON work_places(supervisor_id)"))


def downgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    tables = inspector.get_table_names()
    
    if 'work_places' in tables:
        op.drop_table('work_places')
