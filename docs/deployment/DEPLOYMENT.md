# EthioWorkForce Production Deployment Guide

## Overview

This guide covers the complete deployment process for the EthioWorkForce offline-first workforce management system, including backend API and mobile application.

---

## Backend Deployment (FastAPI)

### Prerequisites

- **Python**: 3.9+
- **PostgreSQL**: 12+
- **Redis**: 6+ (optional, for caching)
- **Server**: Ubuntu 20.04+ or similar Linux distribution

### Environment Configuration

Create a `.env` file in the `backend/` directory:

```bash
# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/ethioworkforce

# Security
SECRET_KEY=your-super-secret-key-change-this-in-production
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS Origins (add your frontend URL)
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com

# Server Configuration
HOST=0.0.0.0
PORT=8000
WORKERS=4

# File Upload
MAX_UPLOAD_SIZE=10485760  # 10MB

# Environment
ENVIRONMENT=production
DEBUG=false
```

### Installation Steps

```bash
# 1. Navigate to backend directory
cd backend

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run database migrations
alembic upgrade head

# 5. Test the application
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Production Deployment with Systemd

Create `/etc/systemd/system/ethioworkforce.service`:

```ini
[Unit]
Description=EthioWorkForce API
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/ethioworkforce/backend
Environment="PATH=/opt/ethioworkforce/backend/venv/bin"
ExecStart=/opt/ethioworkforce/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable ethioworkforce
sudo systemctl start ethioworkforce
sudo systemctl status ethioworkforce
```

### Nginx Reverse Proxy

Create `/etc/nginx/sites-available/ethioworkforce`:

```nginx
server {
    listen 80;
    server_name api.ethioworkforce.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Increase timeout for large file uploads
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
}
```

Enable site and restart Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/ethioworkforce /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### SSL Certificate (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.ethioworkforce.com
```

---

## Mobile App Deployment (Flutter)

### Prerequisites

- **Flutter SDK**: 3.10+
- **Android Studio**: Latest (for Android builds)
- **Xcode**: 14+ (for iOS builds, macOS only)

### Configuration Steps

#### 1. Configure Backend URL

Open the app Settings and configure the backend API URL:

- **Development**: `http://localhost:8000/api/v1` or `http://10.0.2.2:8000/api/v1` (Android emulator)
- **Production**: `https://api.ethioworkforce.com/api/v1`

Or programmatically set default in `lib/core/network/dio_client.dart`:

```dart
static const String defaultProductionUrl = 'https://api.ethioworkforce.com/api/v1';
```

#### 2. Update App Version

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
```

#### 3. Configure App Icons and Splash Screen

Place app icon in `assets/images/app_icon.png` and run:

```bash
flutter pub run flutter_launcher_icons:main
```

#### 4. Audio Assets (Optional)

Add audio feedback files to `assets/sounds/`:
- `success.mp3` - Success sound
- `error.mp3` - Error sound
- `warning.mp3` - Warning sound

**Note**: App gracefully falls back to TTS if audio files are missing.

### Android Build

#### Debug APK (for testing)

```bash
cd frontend
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

#### Signing Configuration

Create `android/key.properties`:

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/path/to/keystore.jks
```

Generate keystore:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Update `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### iOS Build (macOS only)

#### Debug Build

```bash
flutter build ios --debug
```

#### Release Build

```bash
flutter build ios --release
```

Configure signing in Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select Runner > Signing & Capabilities
3. Choose your development team
4. Configure bundle identifier

---

## Database Setup

### PostgreSQL Installation

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Create Database and User

```bash
sudo -u postgres psql

CREATE DATABASE ethioworkforce;
CREATE USER ethio_admin WITH ENCRYPTED PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE ethioworkforce TO ethio_admin;
\q
```

### Initialize Schema

```bash
cd backend
source venv/bin/activate
alembic upgrade head
```

### Backup Strategy

Create daily backup script `/opt/scripts/backup_ethioworkforce.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/ethioworkforce"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Database backup
pg_dump -U ethio_admin ethioworkforce > "$BACKUP_DIR/db_$DATE.sql"

# Keep last 7 days
find $BACKUP_DIR -type f -mtime +7 -delete
```

Add to crontab:

```bash
0 2 * * * /opt/scripts/backup_ethioworkforce.sh
```

---

## Offline-First Architecture Configuration

### Sneakernet Sync Setup

#### Export Data for Offline Sites

1. Navigate to Settings > Sneakernet Sync
2. Click "Export to USB"
3. Enter encryption password
4. Save `.json` file to USB drive

#### Import Data at Head Office

1. Navigate to Settings > Sneakernet Sync
2. Click "Import from USB"
3. Select the `.json` file from USB
4. Enter decryption password
5. Data syncs automatically

#### Security Best Practices

- **Encryption**: All sneakernet packages use AES-256 encryption
- **Password Policy**: Minimum 12 characters, alphanumeric + symbols
- **Checksum Verification**: SHA-256 checksums ensure data integrity
- **Version Control**: Package format versioning prevents incompatible imports

---

## Monitoring and Logging

### Application Logs

Backend logs are written to:
- **Console**: During development
- **File**: `/var/log/ethioworkforce/app.log` (production)

Configure logging in `backend/app/core/config.py`:

```python
LOGGING_CONFIG = {
    "level": "INFO",
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    "handlers": {
        "file": {
            "filename": "/var/log/ethioworkforce/app.log",
            "maxBytes": 10485760,  # 10MB
            "backupCount": 5
        }
    }
}
```

### Health Checks

API health endpoint:

```bash
curl https://api.ethioworkforce.com/health
```

Expected response:

```json
{
  "status": "healthy",
  "database": "connected",
  "version": "1.0.0"
}
```

---

## Security Hardening

### API Security

1. **Enable HTTPS**: Always use SSL/TLS in production
2. **API Authentication**: JWT tokens with 30-minute expiry
3. **Rate Limiting**: Configure Nginx rate limiting
4. **CORS**: Restrict to known frontend domains
5. **Input Validation**: All inputs sanitized and validated

### Mobile App Security

1. **SSL Pinning**: Consider implementing for production
2. **Secure Storage**: Uses Flutter secure_storage for sensitive data
3. **Offline Data**: Local database encrypted with SQLCipher
4. **QR Code Validation**: Server-side verification required

### Password Policy

- Minimum 8 characters
- Must include uppercase, lowercase, number
- Stored as bcrypt hashes

---

## Performance Optimization

### Backend

- **Database Indexing**: All foreign keys and frequently queried fields indexed
- **Connection Pooling**: SQLAlchemy connection pool (5-20 connections)
- **Caching**: Redis caching for frequently accessed data (optional)
- **Pagination**: All list endpoints support pagination

### Mobile App

- **Image Caching**: `cached_network_image` package
- **Lazy Loading**: Lists use pagination and lazy loading
- **Offline Database**: Drift (SQLite) for fast local queries
- **Asset Optimization**: Compressed images and icons

---

## Troubleshooting

### Backend Issues

**Database connection errors:**
```bash
# Check PostgreSQL service
sudo systemctl status postgresql

# Verify connection
psql -U ethio_admin -d ethioworkforce -h localhost
```

**Permission denied errors:**
```bash
# Fix file permissions
sudo chown -R www-data:www-data /opt/ethioworkforce
sudo chmod -R 755 /opt/ethioworkforce
```

### Mobile App Issues

**Build failures:**
```bash
# Clean build cache
flutter clean
flutter pub get
flutter build apk --release
```

**Network errors:**
- Verify backend URL in Settings
- Check firewall rules allow API access
- Test API endpoint manually with curl

**Offline mode not working:**
- Enable offline mode in Settings
- Verify local database initialized
- Check app permissions granted

---

## Support and Maintenance

### Version Updates

**Backend:**
```bash
cd backend
git pull origin main
source venv/bin/activate
pip install -r requirements.txt
alembic upgrade head
sudo systemctl restart ethioworkforce
```

**Mobile App:**
1. Update version in `pubspec.yaml`
2. Build new APK/AAB
3. Distribute to users or upload to Play Store

### Contact

- **Email**: support@ethioworkforce.et
- **Documentation**: https://docs.ethioworkforce.et
- **Issue Tracker**: https://github.com/ethioworkforce/issues

---

## License

Proprietary - EthioWorkForce © 2024
