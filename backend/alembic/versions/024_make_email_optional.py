"""make email optional

Revision ID: 024_make_email_optional
Revises: 023_add_roles_table
Create Date: 2026-02-14

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '024_make_email_optional'
down_revision = '023_add_roles_table'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Make email column nullable in users table
    op.alter_column('users', 'email',
                    existing_type=sa.String(255),
                    nullable=True)
    
    # Make email column nullable in user_registration_requests table
    op.alter_column('user_registration_requests', 'email',
                    existing_type=sa.String(255),
                    nullable=True)
    
    print("Made email column nullable in users and user_registration_requests tables")


def downgrade() -> None:
    # Make email column required again
    op.alter_column('users', 'email',
                    existing_type=sa.String(255),
                    nullable=False)
    
    op.alter_column('user_registration_requests', 'email',
                    existing_type=sa.String(255),
                    nullable=False)
    
    print("Made email column required again in users and user_registration_requests tables")
