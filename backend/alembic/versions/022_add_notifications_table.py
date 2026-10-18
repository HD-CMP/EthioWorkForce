"""add notifications table

Revision ID: 022_add_notifications_table
Revises: 021_create_overtime_table
Create Date: 2026-02-13

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '022_add_notifications_table'
down_revision = '021_create_overtime_table'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'notifications',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('type', sa.String(100), nullable=False),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('message', sa.Text(), nullable=False),
        sa.Column('is_read', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('extra_data', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id')
    )
    
    op.create_index('ix_notifications_id', 'notifications', ['id'])
    op.create_index('ix_notifications_user_id', 'notifications', ['user_id'])
    op.create_index('ix_notifications_type', 'notifications', ['type'])
    op.create_index('ix_notifications_is_read', 'notifications', ['is_read'])
    
    op.create_foreign_key(
        'fk_notifications_user_id',
        'notifications', 'users',
        ['user_id'], ['id'],
        ondelete='CASCADE'
    )
    
    print("Created notifications table")


def downgrade() -> None:
    op.drop_constraint('fk_notifications_user_id', 'notifications', type_='foreignkey')
    
    op.drop_index('ix_notifications_is_read', 'notifications')
    op.drop_index('ix_notifications_type', 'notifications')
    op.drop_index('ix_notifications_user_id', 'notifications')
    op.drop_index('ix_notifications_id', 'notifications')
    
    op.drop_table('notifications')
    
    print("Dropped notifications table")
