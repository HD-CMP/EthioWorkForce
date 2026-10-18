# EthioWorkForce - Backup & Disaster Recovery Guide

**Version**: 1.0.0  
**Date**: January 23, 2026

---

## Table of Contents
1. [Backup Strategy](#backup-strategy)
2. [Automated Backup Setup](#automated-backup-setup)
3. [Manual Backup Procedures](#manual-backup-procedures)
4. [Disaster Recovery Procedures](#disaster-recovery-procedures)
5. [Testing & Validation](#testing--validation)

---

## 1. Backup Strategy

### 1.1 What Gets Backed Up

**Database Backups**:
- PostgreSQL database (all tables and data)
- Frequency: Daily at 2:00 AM
- Retention: 30 days
- Format: Compressed PostgreSQL dump (.dump.gz)

**File Backups**:
- Uploaded files (worker photos, QR codes, evidence files)
- Location: `/opt/ethioworkforce/backend/uploads/`
- Frequency: Daily at 3:00 AM
- Retention: 30 days
- Format: Compressed tar archive (.tar.gz)

**Configuration Backups**:
- `.env` files
- Nginx configuration
- Systemd service files
- Frequency: Weekly
- Retention: 90 days

### 1.2 Backup Locations

**Primary Backup Storage**: `/var/backups/ethioworkforce/`
**Off-site Backup**: USB drive or external server (manual transfer weekly)

---

## 2. Automated Backup Setup

### 2.1 Database Backup Cron Job

```bash
# Edit crontab
sudo crontab -e

# Add this line for daily database backup at 2:00 AM
0 2 * * * /opt/ethioworkforce/backend/scripts/backup_database.sh >> /var/log/ethioworkforce/backup.log 2>&1
```

### 2.2 File Backup Cron Job

```bash
# Add this line for daily file backup at 3:00 AM
0 3 * * * /opt/ethioworkforce/backend/scripts/backup_files.sh >> /var/log/ethioworkforce/backup.log 2>&1
```

### 2.3 Verify Cron Jobs

```bash
sudo crontab -l
```

### 2.4 Environment Variables

Create `/opt/ethioworkforce/backend/scripts/.backup_env`:

```bash
export DB_NAME=ethioworkforce
export DB_USER=postgres
export DB_HOST=localhost
export PGPASSWORD=your_secure_password
```

Make executable:
```bash
chmod 600 /opt/ethioworkforce/backend/scripts/.backup_env
chmod +x /opt/ethioworkforce/backend/scripts/*.sh
```

---

## 3. Manual Backup Procedures

### 3.1 Manual Database Backup

```bash
cd /opt/ethioworkforce/backend/scripts
sudo ./backup_database.sh
```

**Verify backup created**:
```bash
ls -lh /var/backups/ethioworkforce/
```

### 3.2 Manual File Backup

```bash
cd /opt/ethioworkforce/backend/scripts
sudo ./backup_files.sh
```

### 3.3 Full System Backup (Before Updates)

```bash
# 1. Backup database
sudo /opt/ethioworkforce/backend/scripts/backup_database.sh

# 2. Backup files
sudo /opt/ethioworkforce/backend/scripts/backup_files.sh

# 3. Backup configuration
sudo tar -czf /var/backups/ethioworkforce/config_$(date +%Y%m%d).tar.gz \
    /opt/ethioworkforce/backend/.env \
    /etc/nginx/sites-available/ethioworkforce \
    /etc/systemd/system/ethioworkforce.service
```

### 3.4 Export Backup to USB Drive

```bash
# Mount USB drive (usually /media/usb)
# Copy backups
sudo cp /var/backups/ethioworkforce/backup_*.dump.gz /media/usb/
sudo cp /var/backups/ethioworkforce/files/files_backup_*.tar.gz /media/usb/

# Safely eject
sudo umount /media/usb
```

---

## 4. Disaster Recovery Procedures

### 4.1 Complete System Failure

**Prerequisites**:
- New server installed with Ubuntu 20.04+
- PostgreSQL 12+ installed
- Backup files accessible

**Recovery Steps**:

1. **Install Dependencies**:
```bash
sudo apt update
sudo apt install postgresql python3 python3-pip nginx
```

2. **Restore Application Code**:
```bash
cd /opt
sudo git clone <repository_url> ethioworkforce
cd ethioworkforce/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

3. **Create Database**:
```bash
sudo -u postgres psql
CREATE DATABASE ethioworkforce;
CREATE USER ethioworkforce_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE ethioworkforce TO ethioworkforce_user;
\q
```

4. **Restore Database**:
```bash
cd /opt/ethioworkforce/backend/scripts
sudo ./restore_database.sh /path/to/backup_YYYYMMDD_HHMMSS.dump.gz
```

5. **Restore Files**:
```bash
sudo tar -xzf /path/to/files_backup_YYYYMMDD.tar.gz -C /opt/ethioworkforce/backend/
```

6. **Restore Configuration**:
```bash
sudo cp /path/to/backup/.env /opt/ethioworkforce/backend/
sudo cp /path/to/backup/nginx_config /etc/nginx/sites-available/ethioworkforce
sudo ln -s /etc/nginx/sites-available/ethioworkforce /etc/nginx/sites-enabled/
```

7. **Start Services**:
```bash
sudo systemctl restart postgresql
sudo systemctl restart nginx
sudo systemctl start ethioworkforce
```

8. **Verify System**:
```bash
curl http://localhost:8000/health
```

### 4.2 Database Corruption

```bash
# Stop application
sudo systemctl stop ethioworkforce

# Restore from latest backup
cd /opt/ethioworkforce/backend/scripts
sudo ./restore_database.sh /var/backups/ethioworkforce/backup_latest.dump.gz

# Start application
sudo systemctl start ethioworkforce
```

### 4.3 Accidental Data Deletion

```bash
# Use disaster recovery tool
cd /opt/ethioworkforce/backend/scripts
sudo ./disaster_recovery.sh

# Select option 1 (Restore database only)
# Enter backup file from before deletion occurred
```

### 4.4 File System Issues

```bash
# Restore files only
cd /opt/ethioworkforce/backend/scripts
sudo tar -xzf /var/backups/ethioworkforce/files/files_backup_YYYYMMDD.tar.gz \
    -C /opt/ethioworkforce/backend/
```

---

## 5. Testing & Validation

### 5.1 Monthly Backup Test

**Test Procedure** (perform on test server, never production):

1. **Select Random Backup**:
```bash
ls /var/backups/ethioworkforce/ | grep backup | shuf -n 1
```

2. **Restore to Test Database**:
```bash
createdb ethioworkforce_test
pg_restore -d ethioworkforce_test /var/backups/ethioworkforce/backup_YYYYMMDD.dump.gz
```

3. **Verify Data Integrity**:
```bash
psql ethioworkforce_test -c "SELECT COUNT(*) FROM workers;"
psql ethioworkforce_test -c "SELECT COUNT(*) FROM attendance;"
psql ethioworkforce_test -c "SELECT COUNT(*) FROM payroll;"
```

4. **Clean Up**:
```bash
dropdb ethioworkforce_test
```

### 5.2 Backup Validation Checklist

- [ ] Database backup file exists and is not empty
- [ ] Database backup is not corrupted (can be opened)
- [ ] Files backup includes all uploaded files
- [ ] Backup logs show no errors
- [ ] Backup file sizes are reasonable (not 0 bytes)
- [ ] Off-site backup is up to date (within 7 days)

### 5.3 Quarterly Disaster Recovery Drill

**Full DR Test** (on test environment):

1. Simulate complete server failure
2. Build new server from scratch
3. Restore from backup using documented procedures
4. Verify all functionality works
5. Time the recovery process
6. Document any issues encountered
7. Update procedures as needed

**Target Recovery Time**: < 4 hours  
**Target Recovery Point**: < 24 hours (max data loss)

---

## 6. Backup Monitoring

### 6.1 Automated Monitoring Script

Create `/opt/ethioworkforce/backend/scripts/check_backups.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/ethioworkforce"
ALERT_EMAIL="admin@ethioworkforce.et"

LATEST_DB_BACKUP=$(find $BACKUP_DIR -name "backup_*.dump.gz" -mtime -1 | wc -l)
LATEST_FILE_BACKUP=$(find $BACKUP_DIR/files -name "files_backup_*.tar.gz" -mtime -1 | wc -l)

if [ $LATEST_DB_BACKUP -eq 0 ]; then
    echo "WARNING: No database backup in last 24 hours" | mail -s "EthioWorkForce Backup Alert" $ALERT_EMAIL
fi

if [ $LATEST_FILE_BACKUP -eq 0 ]; then
    echo "WARNING: No file backup in last 24 hours" | mail -s "EthioWorkForce Backup Alert" $ALERT_EMAIL
fi
```

### 6.2 Backup Size Monitoring

```bash
#!/bin/bash
du -sh /var/backups/ethioworkforce/
df -h /var/backups/
```

**Alert if**:
- Backup directory > 80% of available disk space
- Backup size suddenly drops (possible corruption)
- Backup size suddenly increases dramatically (investigate)

---

## 7. Emergency Contacts

**Technical Team**:
- Primary: [Name] - [Phone] - [Email]
- Secondary: [Name] - [Phone] - [Email]

**Database Administrator**:
- [Name] - [Phone] - [Email]

**Hosting Provider Support**:
- [Provider Name] - [Phone] - [Support Portal]

---

## 8. Recovery Time Objectives (RTO) & Recovery Point Objectives (RPO)

| Scenario | RTO (Max Downtime) | RPO (Max Data Loss) | Priority |
|----------|-------------------|---------------------|----------|
| Database corruption | 2 hours | 24 hours | Critical |
| File system failure | 4 hours | 24 hours | High |
| Complete server failure | 8 hours | 24 hours | Critical |
| Accidental deletion | 1 hour | Point-in-time | Medium |
| Ransomware attack | 12 hours | 24 hours | Critical |

---

## 9. Backup Restoration Time Estimates

| Backup Type | Size | Restoration Time |
|-------------|------|------------------|
| Database (small) | < 1 GB | 5-10 minutes |
| Database (medium) | 1-10 GB | 15-30 minutes |
| Database (large) | > 10 GB | 30-60 minutes |
| Files | < 5 GB | 10-15 minutes |
| Full system | Variable | 1-4 hours |

---

**Document Owner**: EthioWorkForce Operations Team  
**Last Updated**: January 23, 2026  
**Next Review**: April 23, 2026
