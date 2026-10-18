"""add roles table

Revision ID: 023_add_roles_table
Revises: 022_add_notifications_table
Create Date: 2026-02-13

"""
from alembic import op
import sqlalchemy as sa

revision = '023_add_roles_table'
down_revision = '022_add_notifications_table'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'roles',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('display_name', sa.String(100), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('is_system_role', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name')
    )
    
    op.create_index('ix_roles_id', 'roles', ['id'])
    op.create_index('ix_roles_name', 'roles', ['name'])
    
    # Insert default system roles
    connection = op.get_bind()
    connection.execute(sa.text("""
        INSERT INTO roles (name, display_name, description, is_system_role, is_active)
        VALUES
        ('super_admin', 'Super Admin', 'Full system access with all permissions', true, true),
        ('admin', 'Admin', 'Administrative access to manage users and workplaces', true, true),
        ('site_admin', 'Site Admin', 'Manage specific sites and their workplaces', true, true),
        ('supervisor', 'Supervisor', 'Supervise workers and manage attendance', true, true),
        ('hr_officer', 'HR Officer', 'Human resources and payroll management', true, true),
        ('viewer', 'Viewer', 'Read-only access to view data', true, true)
    """))
    
    print("Created roles table and inserted default system roles")


def downgrade() -> None:
    op.drop_index('ix_roles_name', 'roles')
    op.drop_index('ix_roles_id', 'roles')
    op.drop_table('roles')
    
    print("Dropped roles table")
