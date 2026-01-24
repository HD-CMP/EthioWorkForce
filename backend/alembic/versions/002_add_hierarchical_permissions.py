"""Add hierarchical permissions and user registration approval

Revision ID: 002_hierarchical_permissions
Revises: 001_initial
Create Date: 2026-01-23

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '002_hierarchical_permissions'
down_revision = '001_initial'
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
