"""unique employee_id per site and work_type

Revision ID: 017_employee_id_work_type
Revises: 016_overtime_verification
Create Date: 2026-02-01

"""
from alembic import op
import sqlalchemy as sa


revision = '017_employee_id_work_type'
down_revision = '016_overtime_verification'
branch_labels = None
depends_on = None


def upgrade() -> None:
    from sqlalchemy import inspect
    from alembic import context
    
    conn = context.get_bind()
    inspector = inspect(conn)
    
    # Check if old 2-column constraint exists and drop it
    constraints = inspector.get_unique_constraints('workers')
    for constraint in constraints:
        if constraint['name'] == 'uq_worker_employee_id_work_type':
            op.drop_constraint('uq_worker_employee_id_work_type', 'workers', type_='unique')
            break
    
    # Check if index is unique
    indexes = inspector.get_indexes('workers')
    for idx in indexes:
        if idx['name'] == 'ix_workers_employee_id' and idx.get('unique', False):
            op.drop_index('ix_workers_employee_id', table_name='workers')
            op.create_index(
                'ix_workers_employee_id',
                'workers',
                ['employee_id'],
                unique=False
            )
            break
    
    # Create new 3-column constraint
    op.create_unique_constraint(
        'uq_worker_employee_id_site_work_type',
        'workers',
        ['employee_id', 'site_id', 'work_type_id']
    )


def downgrade() -> None:
    # Drop new 3-column constraint
    op.drop_constraint('uq_worker_employee_id_site_work_type', 'workers', type_='unique')
    
    # Recreate old 2-column constraint
    op.create_unique_constraint(
        'uq_worker_employee_id_work_type',
        'workers',
        ['employee_id', 'work_type_id']
    )
    
    # Drop non-unique index and recreate as unique
    op.drop_index('ix_workers_employee_id', table_name='workers')
    op.create_index(
        'ix_workers_employee_id',
        'workers',
        ['employee_id'],
        unique=True
    )
