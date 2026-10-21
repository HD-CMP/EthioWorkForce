"""add id_card_url to workers

Revision ID: 028_add_id_card_url_to_workers
Revises: 027_link_worker_to_users_and_requests
Create Date: 2026-10-21 15:45:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = '028_add_id_card_url_to_workers'
down_revision = '027_link_worker_to_users_and_requests'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    
    worker_columns = [col['name'] for col in inspector.get_columns('workers')]
    if 'id_card_url' not in worker_columns:
        op.add_column('workers', sa.Column('id_card_url', sa.String(length=500), nullable=True))


def downgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    
    worker_columns = [col['name'] for col in inspector.get_columns('workers')]
    if 'id_card_url' in worker_columns:
        op.drop_column('workers', 'id_card_url')
