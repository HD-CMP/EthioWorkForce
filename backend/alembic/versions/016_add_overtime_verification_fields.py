"""add overtime verification fields

Revision ID: 016_overtime_verification
Revises: 015_overtime_float
Create Date: 2026-01-30

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '016_overtime_verification'
down_revision = '015_overtime_float'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add overtime verification fields to attendances table
    op.add_column('attendances', sa.Column('is_overtime_verified', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('attendances', sa.Column('overtime_verified_by_id', sa.Integer(), nullable=True))
    op.add_column('attendances', sa.Column('overtime_verified_at', sa.DateTime(), nullable=True))
    op.add_column('attendances', sa.Column('is_overtime_locked', sa.Boolean(), nullable=False, server_default='false'))
    
    # Add foreign key constraint for overtime_verified_by_id
    op.create_foreign_key(
        'fk_attendances_overtime_verified_by_users',
        'attendances', 'users',
        ['overtime_verified_by_id'], ['id']
    )


def downgrade() -> None:
    # Drop foreign key constraint
    op.drop_constraint('fk_attendances_overtime_verified_by_users', 'attendances', type_='foreignkey')
    
    # Drop overtime verification fields
    op.drop_column('attendances', 'is_overtime_locked')
    op.drop_column('attendances', 'overtime_verified_at')
    op.drop_column('attendances', 'overtime_verified_by_id')
    op.drop_column('attendances', 'is_overtime_verified')
