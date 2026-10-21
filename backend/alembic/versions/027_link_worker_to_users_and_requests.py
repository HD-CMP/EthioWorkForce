"""link worker to users and user_registration_requests

Revision ID: 027_link_worker_to_users_and_requests
Revises: 026_add_payroll_filters
Create Date: 2026-10-21 11:57:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = '027_link_worker_to_users_and_requests'
down_revision = '026_add_payroll_filters'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    
    # 1. Add worker_id to users
    user_columns = [col['name'] for col in inspector.get_columns('users')]
    if 'worker_id' not in user_columns:
        op.add_column('users', sa.Column('worker_id', sa.Integer(), sa.ForeignKey('workers.id', ondelete='SET NULL'), nullable=True))
        try:
            op.create_unique_constraint('uq_users_worker_id', 'users', ['worker_id'])
        except Exception:
            pass

    # 2. Add worker_id to user_registration_requests
    request_columns = [col['name'] for col in inspector.get_columns('user_registration_requests')]
    if 'worker_id' not in request_columns:
        op.add_column('user_registration_requests', sa.Column('worker_id', sa.Integer(), sa.ForeignKey('workers.id', ondelete='SET NULL'), nullable=True))


def downgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    
    request_columns = [col['name'] for col in inspector.get_columns('user_registration_requests')]
    if 'worker_id' in request_columns:
        op.drop_column('user_registration_requests', 'worker_id')

    user_columns = [col['name'] for col in inspector.get_columns('users')]
    if 'worker_id' in user_columns:
        try:
            op.drop_constraint('uq_users_worker_id', 'users', type_='unique')
        except Exception:
            pass
        op.drop_column('users', 'worker_id')
