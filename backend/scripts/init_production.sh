#!/bin/bash

set -e

echo "========================================"
echo "EthioWorkForce Production Initialization"
echo "========================================"

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "This script will:"
echo "1. Install system dependencies"
echo "2. Set up PostgreSQL database"
echo "3. Configure firewall"
echo "4. Set up backup automation"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    exit 0
fi

echo ""
echo "Step 1/6: Installing system dependencies..."
apt update
apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx git ufw

echo "Step 2/6: Setting up PostgreSQL..."
read -p "Enter database name [ethioworkforce]: " DB_NAME
DB_NAME=${DB_NAME:-ethioworkforce}

read -p "Enter database user [ethioworkforce_user]: " DB_USER
DB_USER=${DB_USER:-ethioworkforce_user}

read -sp "Enter database password: " DB_PASS
echo ""

sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\q
EOF

echo "Database created successfully"

echo "Step 3/6: Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "Step 4/6: Creating backup directories..."
mkdir -p /var/backups/ethioworkforce/files
chmod 700 /var/backups/ethioworkforce

echo "Step 5/6: Setting up automated backups..."
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/ethioworkforce/backend/scripts/backup_database.sh >> /var/log/ethioworkforce/backup.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/ethioworkforce/backend/scripts/backup_files.sh >> /var/log/ethioworkforce/backup.log 2>&1") | crontab -

echo "Step 6/6: Creating environment file template..."
cat > /tmp/ethioworkforce_env_template << EOF
# Database Configuration
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost/$DB_NAME

# Security
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Environment
ENVIRONMENT=production
DEBUG=false

# CORS
CORS_ORIGINS=["https://your-domain.com"]

# Optional: Sentry
SENTRY_DSN=

EOF

echo ""
echo "========================================"
echo "Production Initialization Complete!"
echo "========================================"
echo ""
echo "Database Details:"
echo "  Name: $DB_NAME"
echo "  User: $DB_USER"
echo "  Host: localhost"
echo ""
echo "Environment template created at: /tmp/ethioworkforce_env_template"
echo ""
echo "Next steps:"
echo "1. Run: sudo ./deploy.sh"
echo "2. Copy /tmp/ethioworkforce_env_template to /opt/ethioworkforce/backend/.env"
echo "3. Run: sudo ./ssl_setup.sh (if using custom domain)"
echo ""
