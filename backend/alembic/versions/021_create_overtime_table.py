"""create overtime table and migrate data

Revision ID: 021_create_overtime_table
Revises: 020_work_place_to_workers
Create Date: 2026-02-11

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '021_create_overtime_table'
down_revision = '020_work_place_to_workers'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create overtimes table
    op.create_table(
        'overtimes',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('worker_id', sa.Integer(), nullable=False),
        sa.Column('site_id', sa.Integer(), nullable=False),
        sa.Column('overtime_date', sa.Date(), nullable=False),
        sa.Column('hours', sa.Float(), nullable=False),
        sa.Column('is_verified', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('verified_by_id', sa.Integer(), nullable=True),
        sa.Column('verified_at', sa.DateTime(), nullable=True),
        sa.Column('is_locked', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('ethiopian_date_year', sa.Integer(), nullable=True),
        sa.Column('ethiopian_date_month', sa.Integer(), nullable=True),
        sa.Column('ethiopian_date_day', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id')
    )
    
    op.create_index('ix_overtimes_id', 'overtimes', ['id'])
    op.create_index('ix_overtimes_overtime_date', 'overtimes', ['overtime_date'])
    
    op.create_foreign_key(
        'fk_overtimes_worker_id',
        'overtimes', 'workers',
        ['worker_id'], ['id']
    )
    
    op.create_foreign_key(
        'fk_overtimes_site_id',
        'overtimes', 'sites',
        ['site_id'], ['id']
    )
    
    op.create_foreign_key(
        'fk_overtimes_verified_by_id',
        'overtimes', 'users',
        ['verified_by_id'], ['id']
    )
    
    # Migrate existing overtime data from attendances table
    connection = op.get_bind()
    
    # Insert overtime records from attendance where overtime_hours > 0
    connection.execute(sa.text("""
        INSERT INTO overtimes (
            worker_id,
            site_id,
            overtime_date,
            hours,
            is_verified,
            verified_by_id,
            verified_at,
            is_locked,
            notes,
            ethiopian_date_year,
            ethiopian_date_month,
            ethiopian_date_day,
            created_at,
            updated_at
        )
        SELECT 
            worker_id,
            site_id,
            attendance_date,
            overtime_hours,
            is_overtime_verified,
            overtime_verified_by_id,
            overtime_verified_at,
            is_overtime_locked,
            CASE 
                WHEN status::text = 'absent' THEN 'Overtime without regular attendance'
                ELSE NULL
            END as notes,
            ethiopian_date_year,
            ethiopian_date_month,
            ethiopian_date_day,
            created_at,
            updated_at
        FROM attendances
        WHERE overtime_hours > 0
    """))
    
    print("Migrated overtime data from attendances table to overtimes table")


def downgrade() -> None:
    # Drop foreign key constraints
    op.drop_constraint('fk_overtimes_verified_by_id', 'overtimes', type_='foreignkey')
    op.drop_constraint('fk_overtimes_site_id', 'overtimes', type_='foreignkey')
    op.drop_constraint('fk_overtimes_worker_id', 'overtimes', type_='foreignkey')
    
    # Drop indexes
    op.drop_index('ix_overtimes_overtime_date', 'overtimes')
    op.drop_index('ix_overtimes_id', 'overtimes')
    
    # Drop overtimes table
    op.drop_table('overtimes')
    
    print("Dropped overtimes table - overtime data remains in attendances table")
