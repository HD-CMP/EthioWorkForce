#!/bin/bash

set -e

echo "========================================"
echo "EthioWorkForce Update Script"
echo "========================================"

DEPLOY_DIR="/opt/ethioworkforce"

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "Step 1/8: Creating backup before update..."
/opt/ethioworkforce/backend/scripts/backup_database.sh
/opt/ethioworkforce/backend/scripts/backup_files.sh

echo "Step 2/8: Stopping application..."
systemctl stop ethioworkforce

echo "Step 3/8: Pulling latest code..."
cd $DEPLOY_DIR
git pull

echo "Step 4/8: Updating dependencies..."
cd backend
source venv/bin/activate
pip install --upgrade -r requirements.txt

echo "Step 5/8: Running database migrations..."
alembic upgrade head

echo "Step 6/8: Collecting static files (if applicable)..."
# Add static file collection if needed

echo "Step 7/8: Starting application..."
systemctl start ethioworkforce

echo "Step 8/8: Verifying deployment..."
sleep 5
curl -f http://localhost:8000/health || {
    echo "ERROR: Health check failed!"
    echo "Rolling back..."
    systemctl stop ethioworkforce
    # Restore from backup if needed
    exit 1
}

echo ""
echo "========================================"
echo "Update Complete!"
echo "========================================"
systemctl status ethioworkforce --no-pager
