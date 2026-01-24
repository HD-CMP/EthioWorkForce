#!/bin/bash

BACKUP_DIR="/var/backups/ethioworkforce/files"
DATE=$(date +"%Y%m%d_%H%M%S")
SOURCE_DIR="/opt/ethioworkforce/backend/uploads"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

echo "Starting file backup at $(date)"

tar -czf "$BACKUP_DIR/files_backup_$DATE.tar.gz" -C "$(dirname $SOURCE_DIR)" "$(basename $SOURCE_DIR)"

if [ $? -eq 0 ]; then
    echo "File backup successful: files_backup_$DATE.tar.gz"
    
    find "$BACKUP_DIR" -name "files_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    echo "Old file backups (>$RETENTION_DAYS days) deleted"
    
    echo "File backup completed successfully at $(date)"
else
    echo "ERROR: File backup failed at $(date)"
    exit 1
fi
