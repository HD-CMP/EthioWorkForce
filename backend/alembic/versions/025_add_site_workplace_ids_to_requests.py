"""add site and workplace ids to registration requests

Revision ID: 025_add_site_workplace_ids
Revises: 024_make_email_optional
Create Date: 2026-02-14

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision = '025_add_site_workplace_ids'
down_revision = '024_make_email_optional'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add site_ids and work_place_ids JSON columns to user_registration_requests
    op.add_column('user_registration_requests', 
                  sa.Column('site_ids', sa.JSON(), nullable=True))
    op.add_column('user_registration_requests',
                  sa.Column('work_place_ids', sa.JSON(), nullable=True))
    
    print("Added site_ids and work_place_ids columns to user_registration_requests table")


def downgrade() -> None:
    # Remove the columns
    op.drop_column('user_registration_requests', 'work_place_ids')
    op.drop_column('user_registration_requests', 'site_ids')
    
    print("Removed site_ids and work_place_ids columns from user_registration_requests table")
