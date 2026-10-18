# 🚀 Complete Deployment Guide - From Scratch

## 📋 Table of Contents
1. [Local Database Setup](#1-local-database-setup)
2. [Remote Server Deployment](#2-remote-server-deployment-render--upstash)
3. [Mobile App Deployment](#3-mobile-app-deployment-android)
4. [Testing & Verification](#4-testing--verification)

---

## 1. Local Database Setup

### Step 1.1: Install Prerequisites

**Ubuntu/WSL:**
```bash
# Update system
sudo apt update

# Install PostgreSQL 15
sudo apt install -y postgresql-15 postgresql-contrib-15

# Install Redis
sudo apt install -y redis-server

# Install Python 3.11
sudo apt install -y python3.11 python3.11-venv python3-pip

# Install Docker & Docker Compose (optional, easier way)
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
# Log out and back in for group changes
```

**Windows:**
- Download PostgreSQL: https://www.postgresql.org/download/windows/
- Download Redis: https://github.com/tporadowski/redis/releases
- Or use Docker Desktop: https://www.docker.com/products/docker-desktop/

---

### Step 1.2: Method A - Using Docker Compose (Recommended)

```bash
# Navigate to project
cd /home/hnde/EthioWorkForce

# Start all services (PostgreSQL, Redis, Backend)
docker-compose up -d

# Check if services are running
docker-compose ps

# You should see:
# - ethioworkforce-db (postgres)
# - ethioworkforce-redis (redis)
# - ethioworkforce-backend (fastapi)
# - ethioworkforce-celery (celery worker)
```

**View logs:**
```bash
docker-compose logs -f backend
```

**Stop services:**
```bash
docker-compose down
```

---

### Step 1.3: Method B - Manual Local Setup

#### Start PostgreSQL

**Ubuntu/WSL:**
```bash
# Start PostgreSQL service
sudo service postgresql start

# Create database and user
sudo -u postgres psql
```

**In PostgreSQL shell:**
```sql
CREATE DATABASE ethioworkforce;
CREATE USER postgres WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE ethioworkforce TO postgres;
\q
```

#### Start Redis

```bash
# Start Redis server
redis-server --daemonize yes

# Test Redis
redis-cli ping
# Should return: PONG
```

#### Setup Python Backend

```bash
cd /home/hnde/EthioWorkForce/backend

# Create virtual environment
python3.11 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/Mac
# OR
venv\Scripts\activate  # Windows

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

#### Create .env file

```bash
cd /home/hnde/EthioWorkForce/backend
nano .env
```

**Add this content:**
```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ethioworkforce
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/1
CELERY_RESULT_BACKEND=redis://localhost:6379/2
SECRET_KEY=your-super-secret-key-min-32-characters-long-change-this
ENVIRONMENT=development
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

Press `Ctrl+X`, then `Y`, then `Enter` to save.

---

### Step 1.4: Run Database Migrations

```bash
cd /home/hnde/EthioWorkForce/backend

# Activate virtual environment if not already
source venv/bin/activate

# Run migrations to create tables
alembic upgrade head

# Initialize database with demo data
python scripts/init_db.py
```

**Expected output:**
```
INFO - Created SUPER_ADMIN user
INFO - Created SITE_ADMIN user
INFO - Created ADMIN user
INFO - Created Bole Construction site
INFO - Created Piassa Development site
INFO - Created site assignments
INFO - Created demo work types
INFO - Database initialization completed successfully!
```

---

### Step 1.5: Start Local Backend

**If using Docker Compose:**
Already running! Skip to verification.

**If manual setup:**

**Terminal 1 - FastAPI Backend:**
```bash
cd /home/hnde/EthioWorkForce/backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**Terminal 2 - Celery Worker:**
```bash
cd /home/hnde/EthioWorkForce/backend
source venv/bin/activate
celery -A app.tasks worker --loglevel=info
```

---

### Step 1.6: Verify Local Setup

**Test API health:**
```bash
curl http://localhost:8000/health
```

**Expected response:**
```json
{"status":"healthy","service":"ethioworkforce-api"}
```

**Test login:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

**View API docs:**
Open browser: http://localhost:8000/api/docs

✅ **Local database is now ready!**

---

## 2. Remote Server Deployment (Render + Upstash)

### Step 2.1: Setup Upstash Redis (Free)

1. **Go to Upstash Console:**
   - Open: https://console.upstash.com/
   - Click "Sign Up" (use Google/GitHub)
   - Verify your email

2. **Create Redis Database:**
   - Click "Create Database"
   - **Name**: `ethioworkforce-redis`
   - **Type**: Regional (not global)
   - **Region**: Choose closest to your users
     - For Ethiopia: `eu-central-1` (Frankfurt) or `ap-south-1` (Mumbai)
   - **TLS**: Enabled
   - Click "Create"

3. **Copy Connection Details:**
   - Click on your database
   - Go to "Details" tab
   - Copy these values:

   ```
   UPSTASH_REDIS_REST_URL=https://xxxxx.upstash.io
   UPSTASH_REDIS_REST_TOKEN=xxxxxxxxxxxxxxxx
   ```

   - Or use the Redis URL format:
   ```
   redis://default:YOUR_PASSWORD@YOUR_ENDPOINT:PORT
   ```

   **Save these values for later!**

---

### Step 2.2: Push Code to GitHub

```bash
cd /home/hnde/EthioWorkForce

# Initialize git (if not already)
git init

# Add .gitignore to avoid sensitive files
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
.env
.env.local

# Database
*.db
*.sqlite3

# Logs
*.log
logs/

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build
build/
dist/
*.egg-info/

# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
frontend/build/
frontend/.flutter-plugins
frontend/.flutter-plugins-dependencies
EOF

# Add all files
git add .

# Commit
git commit -m "Initial commit - EthioWorkforce system"

# Create repository on GitHub:
# 1. Go to https://github.com/new
# 2. Repository name: EthioWorkForce
# 3. Make it Private
# 4. Don't initialize with README
# 5. Click "Create repository"

# Add GitHub remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/EthioWorkForce.git

# Push code
git branch -M main
git push -u origin main
```

**Enter your GitHub username and password (or token).**

---

### Step 2.3: Deploy to Render

#### Option A: Automatic Deployment (Using Blueprint)

1. **Go to Render Dashboard:**
   - Open: https://dashboard.render.com/
   - Sign up using GitHub account (recommended)

2. **Create New Blueprint:**
   - Click "New" → "Blueprint"
   - Click "Connect a repository"
   - Authorize Render to access GitHub
   - Select `EthioWorkForce` repository
   - Click "Connect"

3. **Configure Environment Variables:**
   Render will detect `backend/render.yaml` automatically.
   
   Click "Environment" and add these variables:
   
   ```
   REDIS_URL=redis://default:YOUR_PASSWORD@YOUR_ENDPOINT:PORT
   CELERY_BROKER_URL=redis://default:YOUR_PASSWORD@YOUR_ENDPOINT:PORT/1
   CELERY_RESULT_BACKEND=redis://default:YOUR_PASSWORD@YOUR_ENDPOINT:PORT/2
   CORS_ORIGINS=*
   ```
   
   Replace with your actual Upstash Redis URL from Step 2.1.
   
   Note: `SECRET_KEY` will be auto-generated by Render.

4. **Deploy:**
   - Click "Apply"
   - Wait 5-10 minutes for deployment
   - Watch the logs in real-time

#### Option B: Manual Deployment

**2.3.1 Create PostgreSQL Database:**
- Dashboard → "New" → "PostgreSQL"
- **Name**: `ethioworkforce-db`
- **Database**: `ethioworkforce`
- **User**: `ethioworkforce_user`
- **Region**: Same as your Redis
- **Plan**: Free
- Click "Create Database"
- **Copy the Internal Database URL** (starts with `postgresql://`)

**2.3.2 Create Web Service:**
- Dashboard → "New" → "Web Service"
- Connect GitHub repository: `EthioWorkForce`
- **Name**: `ethioworkforce-api`
- **Region**: Same as PostgreSQL
- **Branch**: `main`
- **Root Directory**: `backend`
- **Runtime**: Python 3
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- **Plan**: Free
- **Environment Variables**:
  ```
  DATABASE_URL=[From PostgreSQL dashboard]
  REDIS_URL=[Your Upstash URL]
  CELERY_BROKER_URL=[Your Upstash URL]/1
  CELERY_RESULT_BACKEND=[Your Upstash URL]/2
  SECRET_KEY=[Generate random 32+ characters]
  ENVIRONMENT=production
  CORS_ORIGINS=*
  ```
- Click "Create Web Service"

**2.3.3 Create Celery Worker:**
- Dashboard → "New" → "Background Worker"
- Connect same repository
- **Name**: `ethioworkforce-celery`
- **Region**: Same as above
- **Branch**: `main`
- **Root Directory**: `backend`
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: `celery -A app.tasks worker --loglevel=info`
- **Plan**: Free
- **Environment Variables**: (Same as web service)
- Click "Create Background Worker"

---

### Step 2.4: Run Migrations on Render

1. **Wait for deployment to complete** (both services show "Live")

2. **Open Web Service Dashboard:**
   - Click on `ethioworkforce-api`
   - Go to "Shell" tab

3. **Run migrations:**
   ```bash
   # Navigate to backend
   cd backend
   
   # Run migrations
   alembic upgrade head
   
   # Initialize database with demo data
   python scripts/init_db.py
   ```

4. **Verify output:**
   ```
   INFO - Created SUPER_ADMIN user
   INFO - Created SITE_ADMIN user
   ...
   INFO - Database initialization completed successfully!
   ```

---

### Step 2.5: Get Your API URL

Your backend is now live at:
```
https://ethioworkforce-api.onrender.com
```

**Test it:**
```bash
curl https://ethioworkforce-api.onrender.com/health
```

**API Base URL for mobile app:**
```
https://ethioworkforce-api.onrender.com/api/v1
```

**View API docs:**
```
https://ethioworkforce-api.onrender.com/api/docs
```

✅ **Remote server is now deployed!**

---

## 3. Mobile App Deployment (Android)

### Step 3.1: Install Flutter

**Ubuntu/WSL:**
```bash
# Download Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter --version
flutter doctor
```

**Windows:**
- Download: https://docs.flutter.dev/get-started/install/windows
- Extract to `C:\flutter`
- Add `C:\flutter\bin` to PATH
- Run: `flutter doctor`

**Install Android SDK:**
- Download Android Studio: https://developer.android.com/studio
- Install Android SDK (API level 34)
- Accept licenses: `flutter doctor --android-licenses`

---

### Step 3.2: Build Android APK

```bash
cd /home/hnde/EthioWorkForce/frontend

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Build APK for all architectures
flutter build apk --release --split-per-abi
```

**Or use the build script:**
```bash
chmod +x build_android.sh
./build_android.sh
```

**Build time:** 5-10 minutes

**Output location:**
```
frontend/build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk      (Most modern phones - USE THIS)
├── app-armeabi-v7a-release.apk    (Older Android devices)
└── app-x86_64-release.apk         (Emulators only)
```

**File size:** ~20-30 MB per APK

---

### Step 3.3: Transfer APK to Phone

**Method 1: USB Cable**
```bash
# Enable USB debugging on phone:
# Settings → About Phone → Tap "Build Number" 7 times
# Settings → Developer Options → Enable USB Debugging

# Connect phone via USB
adb devices

# Install APK directly
adb install frontend/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

**Method 2: Cloud Storage**
- Upload APK to Google Drive / Dropbox
- Download on phone
- Install

**Method 3: File Transfer**
- Use cable to copy APK to phone's Download folder
- Use file manager on phone to locate and install

---

### Step 3.4: Install on Android Phone

1. **Enable Unknown Sources:**
   - Settings → Security → Unknown Sources (Enable)
   - Or: Settings → Apps → Special Access → Install Unknown Apps → Enable for File Manager/Chrome

2. **Install APK:**
   - Open File Manager on phone
   - Navigate to Downloads folder
   - Tap `app-arm64-v8a-release.apk`
   - Click "Install"
   - Wait for installation
   - Click "Open"

3. **Grant Permissions:**
   - Camera (for QR scanning)
   - Storage (for exports)
   - Network (for syncing)

---

### Step 3.5: Configure Mobile App

1. **Open EthioWorkforce App**

2. **First Launch:**
   - Skip intro screens or complete onboarding

3. **Go to Settings:**
   - Tap hamburger menu (☰)
   - Tap "Settings"

4. **Configure Backend URL:**
   - Scroll to "Backend Configuration"
   - Tap "Backend API URL"
   - Enter: `https://ethioworkforce-api.onrender.com/api/v1`
   - Tap "Save"
   - You should see: "Backend URL updated successfully" ✅

5. **Test Connection:**
   - Go back to home/login screen
   - Backend should be reachable

---

### Step 3.6: Login with Demo Account

**SUPER_ADMIN:**
- Username: `admin`
- Password: `admin123`

**ADMIN:**
- Username: `adminuser`
- Password: `admin123`

**SITE_ADMIN:**
- Username: `siteadmin`
- Password: `siteadmin123`

---

## 4. Testing & Verification

### Step 4.1: Test Backend Endpoints

**From phone or computer:**

**1. Health Check:**
```bash
curl https://ethioworkforce-api.onrender.com/health
```

**2. Login:**
```bash
curl -X POST https://ethioworkforce-api.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

**Copy the `access_token` from response.**

**3. List Sites:**
```bash
curl https://ethioworkforce-api.onrender.com/api/v1/sites \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**4. List Work Types:**
```bash
curl https://ethioworkforce-api.onrender.com/api/v1/work-types \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

### Step 4.2: Test Mobile App Features

✅ **Authentication:**
- [ ] Login with admin credentials
- [ ] Token stored and persists
- [ ] Logout works

✅ **Sites Management:**
- [ ] View existing sites
- [ ] Create new site (ADMIN only)
- [ ] Update site details
- [ ] Site appears in worker creation

✅ **Work Types:**
- [ ] View existing work types (Carpenter, Daily Laborer, etc.)
- [ ] Create custom work type (ADMIN/HR only)
- [ ] Edit work type settings
- [ ] Overtime settings visible

✅ **Workers:**
- [ ] Create new worker
- [ ] Assign work type to worker
- [ ] Generate QR code for worker
- [ ] View worker details
- [ ] Update worker info

✅ **Attendance:**
- [ ] Scan QR code to mark attendance
- [ ] Manual attendance entry
- [ ] Add overtime hours
- [ ] View attendance history
- [ ] Verify attendance

✅ **Payroll:**
- [ ] Create payroll period
- [ ] Calculate payroll (includes overtime)
- [ ] View payroll items per worker
- [ ] See gross/net salary breakdown
- [ ] Export payroll report

✅ **Offline Mode:**
- [ ] Enable offline mode in settings
- [ ] App works without internet
- [ ] Data saved locally
- [ ] Disable offline mode
- [ ] Data syncs to server

✅ **Permissions:**
- [ ] SUPER_ADMIN can approve user registrations
- [ ] ADMIN cannot access SUPER_ADMIN functions
- [ ] SITE_ADMIN only sees assigned sites
- [ ] VIEWER has read-only access

---

### Step 4.3: Test Overtime Calculation

**1. Create Worker with Overtime-Eligible Work Type:**
- Login as ADMIN
- Go to Work Types
- Create or verify "Daily Laborer" has:
  - `overtime_eligible: true`
  - `overtime_multiplier: 1.5`
  - `base_rate: 300 ETB`

**2. Create Worker:**
- Go to Workers → Add Worker
- Name: Test Worker
- Work Type: Daily Laborer
- Site: Bole Construction Site
- Hire Date: Today

**3. Mark Attendance with Overtime:**
- Go to Attendance → Mark Attendance
- Select Test Worker
- Date: Today
- Status: Present
- Regular Hours: 8
- **Overtime Hours: 3**
- Save

**4. Calculate Payroll:**
- Go to Payroll → Create Payroll
- Period: This week
- Site: Bole Construction Site
- Click "Calculate"

**5. Verify Calculation:**
Expected for 1 day:
```
Base Pay: 300 ETB (1 day × 300)
Overtime Pay: 168.75 ETB (300 ÷ 8 × 3 × 1.5)
Gross Salary: 468.75 ETB
Taxes: (Applied per tax rule)
Net Salary: (After deductions)
```

✅ **Overtime is working!**

---

## 5. Troubleshooting

### Local Database Issues

**PostgreSQL not starting:**
```bash
sudo service postgresql restart
sudo -u postgres psql -c "SELECT version();"
```

**Redis not running:**
```bash
redis-cli ping
# If fails:
redis-server --daemonize yes
```

**Migration errors:**
```bash
# Drop and recreate database
sudo -u postgres psql
DROP DATABASE ethioworkforce;
CREATE DATABASE ethioworkforce;
\q

# Re-run migrations
alembic upgrade head
python scripts/init_db.py
```

---

### Render Deployment Issues

**Service not starting:**
- Check Render logs: Dashboard → Service → Logs
- Verify all environment variables are set
- Ensure DATABASE_URL is the "Internal Connection String"

**Database connection failed:**
- Use Internal Database URL (not External)
- Format: `postgresql://user:password@internal-host/dbname`
- Check database is in same region as web service

**First request very slow (30+ seconds):**
- This is normal for Render free tier
- Service sleeps after 15 minutes of inactivity
- First request wakes it up
- Solution: Upgrade to Starter plan ($7/mo)

**Migrations not running:**
- Open Shell in Render dashboard
- Manually run:
  ```bash
  cd backend
  alembic upgrade head
  python scripts/init_db.py
  ```

---

### Mobile App Issues

**"Cannot connect to backend":**
1. Check backend URL is correct
2. Ensure backend is running (visit /health endpoint)
3. Check phone has internet connection
4. Try disabling offline mode
5. Verify CORS_ORIGINS includes `*` or your domain

**APK won't install:**
1. Enable "Install from Unknown Sources"
2. Check APK is for correct architecture (use arm64-v8a)
3. Ensure sufficient storage space
4. Try uninstalling old version first

**App crashes on startup:**
1. Check Android version (minimum: 6.0 / API 24)
2. View logs: `adb logcat | grep Flutter`
3. Reinstall the APK
4. Clear app data: Settings → Apps → EthioWorkforce → Storage → Clear Data

**Offline mode not syncing:**
1. Disable offline mode in settings
2. Ensure phone has internet
3. Login again to refresh token
4. Check backend is reachable

---

## 6. Next Steps

### For Production Use

✅ **Security:**
- [ ] Change all default passwords
- [ ] Generate strong SECRET_KEY
- [ ] Use environment-specific configs
- [ ] Enable HTTPS (Render provides free SSL)
- [ ] Restrict CORS_ORIGINS to your domain

✅ **Monitoring:**
- [ ] Set up Sentry for error tracking
- [ ] Enable Render alerts
- [ ] Monitor Upstash usage
- [ ] Set up health check pings

✅ **Backups:**
- [ ] Export database regularly
- [ ] Download backups from Render
- [ ] Store backups securely off-site

✅ **Performance:**
- [ ] Upgrade Render to Starter plan ($7/mo) - no sleep
- [ ] Upgrade PostgreSQL for more storage
- [ ] Monitor Upstash Redis usage (500K commands/month limit)

✅ **Mobile:**
- [ ] Deploy to Google Play Store ($25 one-time)
- [ ] Build iOS version (requires macOS + $99/year)
- [ ] Add custom branding and logo
- [ ] Configure app permissions

---

## 7. Cost Summary

| Component | Free Tier | Usage | Paid Option |
|-----------|-----------|-------|-------------|
| **Local Development** | ✅ Free | Unlimited | N/A |
| **Render Web Service** | ✅ Free | 750 hrs/mo, sleeps after 15min | $7/mo (always-on) |
| **Render PostgreSQL** | ✅ Free | 1GB, 90-day expiry | $7/mo (10GB) |
| **Render Celery Worker** | ✅ Free | 750 hrs/mo | $7/mo |
| **Upstash Redis** | ✅ Free | 256MB, 500K cmds/mo | $10/mo (1GB) |
| **Android APK** | ✅ Free | Unlimited installs | N/A |
| **Google Play Store** | $25 one-time | Unlimited | N/A |
| **Apple App Store** | $99/year | iOS required | N/A |

**Total Monthly Cost: $0** (with free tiers)

**Production Cost: ~$21/mo** (Render Starter + Upstash Pro)

---

## 8. Quick Command Reference

### Local Development

```bash
# Start everything
docker-compose up -d

# View logs
docker-compose logs -f

# Stop everything
docker-compose down

# Rebuild after changes
docker-compose up -d --build

# Run migrations
docker exec -it ethioworkforce-backend alembic upgrade head

# Initialize database
docker exec -it ethioworkforce-backend python scripts/init_db.py
```

### Build Mobile App

```bash
cd frontend

# Clean build
flutter clean && flutter pub get

# Build APK
flutter build apk --release --split-per-abi

# Install on connected phone
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Deploy to Render

```bash
# Push to GitHub
git add .
git commit -m "Update deployment"
git push origin main

# Render auto-deploys from GitHub
```

---

## 🎉 Congratulations!

You now have a fully deployed mobile workforce management system!

**What you've accomplished:**
✅ Local PostgreSQL + Redis database
✅ Remote backend on Render (free)
✅ Redis cache on Upstash (free)
✅ Android mobile app deployed
✅ Hierarchical permissions system
✅ Overtime calculation working
✅ Site-based access control
✅ Offline-first mobile app

**Your system is production-ready!** 🚀
