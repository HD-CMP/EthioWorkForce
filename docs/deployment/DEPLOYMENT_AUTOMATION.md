# EthioWorkForce - Deployment Automation Guide

**Version**: 1.0.0  
**Date**: January 23, 2026

---

## Quick Start Deployment

### Fresh Installation (New Server)

```bash
# 1. Clone repository
git clone <repository_url> /opt/ethioworkforce
cd /opt/ethioworkforce/backend/scripts

# 2. Make scripts executable
chmod +x *.sh

# 3. Initialize production environment
sudo ./init_production.sh

# 4. Deploy application
sudo ./deploy.sh

# 5. Set up SSL (optional but recommended)
sudo ./ssl_setup.sh
```

**Total Time**: ~15-20 minutes

---

## Deployment Scripts Reference

### 1. init_production.sh

**Purpose**: One-time server setup

**What it does**:
- Installs system dependencies (Python, PostgreSQL, Nginx)
- Creates database and user
- Configures firewall (UFW)
- Sets up backup directories
- Creates automated backup cron jobs
- Generates secure environment template

**Usage**:
```bash
sudo ./init_production.sh
```

**Requirements**:
- Fresh Ubuntu 20.04+ server
- Root access
- Internet connection

---

### 2. deploy.sh

**Purpose**: Deploy or redeploy application

**What it does**:
- Clones/updates code from repository
- Sets up Python virtual environment
- Installs dependencies
- Creates .env file from template
- Runs database migrations
- Creates systemd service
- Configures Nginx reverse proxy
- Starts application

**Usage**:
```bash
sudo ./deploy.sh
```

**Post-deployment checks**:
```bash
# Check service status
systemctl status ethioworkforce

# Check health endpoint
curl http://localhost:8000/health

# Check logs
journalctl -u ethioworkforce -f
```

---

### 3. update.sh

**Purpose**: Update running application to latest version

**What it does**:
- Creates automatic backup before update
- Stops application
- Pulls latest code
- Updates dependencies
- Runs new migrations
- Restarts application
- Verifies health

**Usage**:
```bash
sudo ./update.sh
```

**Rollback on failure**: Automatic if health check fails

---

### 4. ssl_setup.sh

**Purpose**: Install and configure SSL certificate

**What it does**:
- Installs Certbot
- Obtains Let's Encrypt certificate
- Configures Nginx for HTTPS
- Sets up auto-renewal

**Usage**:
```bash
sudo ./ssl_setup.sh
```

**Requirements**:
- Domain name pointing to server
- Port 80 accessible from internet

---

### 5. backup_database.sh

**Purpose**: Backup PostgreSQL database

**What it does**:
- Creates compressed database dump
- Stores in /var/backups/ethioworkforce/
- Deletes backups older than 30 days

**Usage**:
```bash
sudo ./backup_database.sh
```

**Manual backup before risky operations**:
```bash
sudo ./backup_database.sh
ls -lh /var/backups/ethioworkforce/
```

---

### 6. restore_database.sh

**Purpose**: Restore database from backup

**What it does**:
- Stops database connections
- Restores from specified backup file
- Verifies restoration

**Usage**:
```bash
sudo ./restore_database.sh /var/backups/ethioworkforce/backup_20260123_140000.dump.gz
```

**⚠️ WARNING**: This will replace all current data

---

### 7. backup_files.sh

**Purpose**: Backup uploaded files

**What it does**:
- Creates compressed archive of uploads directory
- Stores in /var/backups/ethioworkforce/files/
- Deletes file backups older than 30 days

**Usage**:
```bash
sudo ./backup_files.sh
```

---

### 8. disaster_recovery.sh

**Purpose**: Interactive disaster recovery

**What it does**:
- Lists available backups
- Provides menu for recovery options
- Guides through restoration process

**Usage**:
```bash
sudo ./disaster_recovery.sh
```

---

## Automated Deployment with CI/CD

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/ethioworkforce
            git pull
            sudo /opt/ethioworkforce/backend/scripts/update.sh
```

**Required Secrets**:
- `SERVER_HOST`: Production server IP/domain
- `SERVER_USER`: SSH username
- `SSH_PRIVATE_KEY`: SSH private key for authentication

---

## Environment-Specific Configurations

### Development

```bash
# .env.development
ENVIRONMENT=development
DEBUG=true
DATABASE_URL=postgresql://user:pass@localhost/ethioworkforce_dev
CORS_ORIGINS=["http://localhost:3000"]
```

### Staging

```bash
# .env.staging
ENVIRONMENT=staging
DEBUG=false
DATABASE_URL=postgresql://user:pass@staging-db/ethioworkforce_staging
CORS_ORIGINS=["https://staging.ethioworkforce.com"]
```

### Production

```bash
# .env.production
ENVIRONMENT=production
DEBUG=false
DATABASE_URL=postgresql://user:pass@prod-db/ethioworkforce
CORS_ORIGINS=["https://app.ethioworkforce.com"]
SENTRY_DSN=https://...
```

---

## Monitoring & Health Checks

### Automated Health Monitoring

Create `/opt/ethioworkforce/backend/scripts/health_monitor.sh`:

```bash
#!/bin/bash

HEALTH_URL="http://localhost:8000/health"
ALERT_EMAIL="admin@ethioworkforce.et"

response=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ $response -ne 200 ]; then
    echo "ALERT: EthioWorkForce API is down (HTTP $response)" | \
        mail -s "EthioWorkForce Health Alert" $ALERT_EMAIL
    
    # Auto-restart attempt
    systemctl restart ethioworkforce
fi
```

**Add to crontab** (check every 5 minutes):
```bash
*/5 * * * * /opt/ethioworkforce/backend/scripts/health_monitor.sh
```

---

## Troubleshooting Common Issues

### Service Won't Start

```bash
# Check logs
journalctl -u ethioworkforce -n 50

# Check database connection
psql -U ethioworkforce_user -d ethioworkforce -c "SELECT 1;"

# Verify environment variables
cat /opt/ethioworkforce/backend/.env

# Test manual start
cd /opt/ethioworkforce/backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Database Migration Errors

```bash
# Check current migration version
cd /opt/ethioworkforce/backend
source venv/bin/activate
alembic current

# Manually run migrations
alembic upgrade head

# Downgrade if needed
alembic downgrade -1
```

### Nginx 502 Bad Gateway

```bash
# Check if backend is running
systemctl status ethioworkforce

# Check Nginx logs
tail -f /var/log/nginx/error.log

# Test backend directly
curl http://localhost:8000/health

# Restart services
systemctl restart ethioworkforce
systemctl restart nginx
```

### Permission Issues

```bash
# Fix ownership
chown -R www-data:www-data /opt/ethioworkforce
chown -R www-data:www-data /var/log/ethioworkforce

# Fix permissions
chmod -R 755 /opt/ethioworkforce
chmod 600 /opt/ethioworkforce/backend/.env
```

---

## Rollback Procedures

### Rollback to Previous Version

```bash
# 1. Stop application
sudo systemctl stop ethioworkforce

# 2. Restore database backup
sudo ./restore_database.sh /var/backups/ethioworkforce/backup_YYYYMMDD.dump.gz

# 3. Revert code
cd /opt/ethioworkforce
git log --oneline  # Find commit hash
git checkout <previous_commit_hash>

# 4. Restore dependencies
cd backend
source venv/bin/activate
pip install -r requirements.txt

# 5. Restart application
sudo systemctl start ethioworkforce
```

---

## Security Hardening Post-Deployment

```bash
# 1. Disable password authentication for SSH
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
systemctl restart sshd

# 2. Enable fail2ban
apt install fail2ban
systemctl enable fail2ban

# 3. Set up automatic security updates
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# 4. Harden Nginx
# Add security headers to /etc/nginx/sites-available/ethioworkforce
```

---

**Document Owner**: EthioWorkForce DevOps Team  
**Last Updated**: January 23, 2026  
**Next Review**: February 23, 2026
