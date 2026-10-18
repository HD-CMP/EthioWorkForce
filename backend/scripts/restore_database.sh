#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./restore_database.sh <backup_file>"
    echo "Example: ./restore_database.sh /var/backups/ethioworkforce/backup_20260123_140000.dump.gz"
    exit 1
fi

BACKUP_FILE=$1
DB_NAME="${DB_NAME:-ethioworkforce}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "WARNING: This will REPLACE all data in database '$DB_NAME'"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo "Starting database restore at $(date)"

if [[ $BACKUP_FILE == *.gz ]]; then
    echo "Decompressing backup file..."
    gunzip -k "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE%.gz}"
fi

echo "Dropping existing database connections..."
psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DB_NAME';"

echo "Restoring database from $BACKUP_FILE..."
pg_restore -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c -v "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "Database restore completed successfully at $(date)"
else
    echo "ERROR: Database restore failed at $(date)"
    exit 1
fi
