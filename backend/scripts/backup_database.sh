#!/bin/bash

BACKUP_DIR="/var/backups/ethioworkforce"
DATE=$(date +"%Y%m%d_%H%M%S")
DB_NAME="${DB_NAME:-ethioworkforce}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

echo "Starting database backup at $(date)"

pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -F c -b -v -f "$BACKUP_DIR/backup_$DATE.dump"

if [ $? -eq 0 ]; then
    echo "Database backup successful: backup_$DATE.dump"
    
    gzip "$BACKUP_DIR/backup_$DATE.dump"
    echo "Backup compressed: backup_$DATE.dump.gz"
    
    find "$BACKUP_DIR" -name "backup_*.dump.gz" -mtime +$RETENTION_DAYS -delete
    echo "Old backups (>$RETENTION_DAYS days) deleted"
    
    echo "Backup completed successfully at $(date)"
else
    echo "ERROR: Database backup failed at $(date)"
    exit 1
fi
