#!/bin/bash

echo "========================================="
echo "EthioWorkForce Disaster Recovery Tool"
echo "========================================="
echo ""

DB_BACKUP_DIR="/var/backups/ethioworkforce"
FILES_BACKUP_DIR="/var/backups/ethioworkforce/files"

echo "Available database backups:"
ls -lh "$DB_BACKUP_DIR"/backup_*.dump.gz 2>/dev/null | tail -10

echo ""
echo "Available file backups:"
ls -lh "$FILES_BACKUP_DIR"/files_backup_*.tar.gz 2>/dev/null | tail -10

echo ""
echo "Recovery Options:"
echo "1. Restore database only"
echo "2. Restore files only"
echo "3. Full system restore (database + files)"
echo "4. Exit"
echo ""

read -p "Select option (1-4): " option

case $option in
    1)
        read -p "Enter database backup file path: " db_file
        ./restore_database.sh "$db_file"
        ;;
    2)
        read -p "Enter files backup file path: " files_file
        echo "Restoring files from $files_file..."
        tar -xzf "$files_file" -C /opt/ethioworkforce/backend/
        echo "Files restored successfully"
        ;;
    3)
        read -p "Enter database backup file path: " db_file
        read -p "Enter files backup file path: " files_file
        
        echo "Step 1/2: Restoring database..."
        ./restore_database.sh "$db_file"
        
        echo "Step 2/2: Restoring files..."
        tar -xzf "$files_file" -C /opt/ethioworkforce/backend/
        
        echo "Full system restore completed successfully"
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
