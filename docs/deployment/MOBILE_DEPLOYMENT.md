# 📱 Mobile Deployment Guide - EthioWorkforce

## Quick Start Summary

**Free Cloud Hosting Solution:**
- ✅ **Render** - FastAPI backend + PostgreSQL (Free)
- ✅ **Upstash** - Redis serverless (Free: 256MB, 500K cmds/month)
- ✅ **Android APK** - Direct mobile deployment

---

## 🚀 Step-by-Step Deployment

### Part 1: Backend Deployment (Render + Upstash)

#### 1.1 Setup Upstash Redis

1. **Create Account**: https://console.upstash.com/
2. **Create Database**:
   - Click "Create Database"
   - Name: `ethioworkforce-redis`
   - Type: `Regional`
   - Region: Choose closest to Ethiopia (Europe/Middle East)
   - Plan: **Free** ✅
3. **Copy Connection Details**:
   ```
   Database URL: redis://default:YOUR_PASSWORD@ENDPOINT:PORT
   ```
   Save this for later!

#### 1.2 Deploy to Render

1. **Push Code to GitHub**:
   ```bash
   cd /home/hnde/EthioWorkForce
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

2. **Create Render Account**: https://dashboard.render.com/

3. **Deploy Using Blueprint** (Automatic):
   - Click "New" → "Blueprint"
   - Connect your GitHub repository
   - Render auto-detects `backend/render.yaml`
   - Add environment variables:
     - `REDIS_URL`: Your Upstash URL
     - `CELERY_BROKER_URL`: Your Upstash URL (append `/1`)
     - `CELERY_RESULT_BACKEND`: Your Upstash URL (append `/2`)
     - `CORS_ORIGINS`: `*`
   - Click "Apply"

4. **Wait for Deployment** (5-10 minutes)

5. **Run Database Setup**:
   - Go to your web service dashboard
   - Click "Shell" tab
   - Run:
     ```bash
     cd backend
     alembic upgrade head
     python scripts/init_db.py
     ```

6. **Get Your API URL**:
   ```
   https://ethioworkforce-api.onrender.com/api/v1
   ```
   Test it: `https://ethioworkforce-api.onrender.com/health`

---

### Part 2: Build Mobile App

#### 2.1 Build Android APK (Quick Test)

**Linux/Mac:**
```bash
cd frontend
./build_android.sh
```

**Windows:**
```bash
cd frontend
build_android.bat
```

**Manual Build:**
```bash
cd frontend
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release --split-per-abi
```

**Output Location:**
```
frontend/build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk      ← Most phones (use this)
├── app-armeabi-v7a-release.apk    ← Older devices
└── app-x86_64-release.apk         ← Emulators
```

#### 2.2 Install on Android Phone

1. **Transfer APK**:
   - USB cable, Bluetooth, Email, or Cloud storage
   - Use `app-arm64-v8a-release.apk` for modern phones

2. **Enable Installation**:
   - Settings → Security → Install from Unknown Sources
   - Or: Settings → Apps → Special Access → Install Unknown Apps

3. **Install**:
   - Open the APK file on your phone
   - Click "Install"
   - Open "EthioWorkforce"

---

### Part 3: Configure Mobile App

#### 3.1 Connect to Cloud Backend

1. Open app → Settings
2. Backend Configuration → Configure Backend URL
3. Enter: `https://ethioworkforce-api.onrender.com/api/v1`
4. Click Save
5. Login with demo credentials:
   - **SUPER_ADMIN**: `admin` / `admin123`
   - **ADMIN**: `adminuser` / `admin123`
   - **SITE_ADMIN**: `siteadmin` / `siteadmin123`

#### 3.2 Test Offline Mode

1. Settings → Offline Mode → Enable
2. App now works without internet
3. Data syncs when you go back online

---

## 🏠 Local Network Testing (No Cloud Required)

If you want to test locally before deploying to cloud:

### Step 1: Start Backend Locally

```bash
cd /home/hnde/EthioWorkForce
docker-compose up -d
```

### Step 2: Find Your Computer's IP

**Linux/WSL:**
```bash
ip addr show | grep inet | grep -v 127.0.0.1
```

**Windows (CMD/PowerShell):**
```
ipconfig
```

Look for `IPv4 Address` (e.g., `192.168.1.100`)

### Step 3: Configure Mobile App

1. Make sure phone and computer are on **same WiFi**
2. Open app → Settings → Backend Configuration
3. Enter: `http://192.168.1.100:8000/api/v1`
4. Save and test

---

## 🏪 Play Store Deployment (Optional)

### Prerequisites
- Google Play Developer Account ($25 one-time fee)
- Android signing key

### Step 1: Generate Signing Key

```bash
cd frontend
./generate_keystore.sh
```

Follow the prompts to create keystore.

### Step 2: Configure Signing

Create `frontend/android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ethioworkforce
storeFile=/path/to/ethioworkforce-key.jks
```

### Step 3: Build App Bundle

```bash
cd frontend
./build_appbundle.sh
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 4: Upload to Play Console

1. Go to https://play.google.com/console
2. Create new app
3. Upload app bundle
4. Fill in app details, screenshots
5. Submit for review

---

## ⚠️ Important Notes

### Render Free Tier Limitations
- **Services sleep after 15 min** of inactivity
- First request after sleep: **~30 seconds delay**
- **750 hours/month** compute (enough for 1 service always-on)
- PostgreSQL: **1GB storage**, expires after 90 days without activity

### Solutions for Sleep Issue
- Upgrade to Starter plan: **$7/month** (no sleep)
- Or use a health check service to ping every 10 minutes

### Mobile Data Usage
- Offline-first design minimizes data usage
- Only syncs when needed
- Perfect for Ethiopian network conditions

---

## 🔧 Troubleshooting

### "Cannot connect to backend"
- ✅ Check backend URL is correct
- ✅ Ensure backend is running (visit `/health` endpoint)
- ✅ Check CORS settings in backend
- ✅ Verify phone has internet/WiFi

### "Backend is slow"
- Render free tier sleeps - first request takes 30s
- Upgrade to paid plan for instant response

### "Import failed" during database setup
- Make sure all migrations ran: `alembic upgrade head`
- Check database URL is correct
- Verify PostgreSQL is running on Render

### App crashes on startup
- Check minimum Android version (API 24+)
- Reinstall the APK
- Check logs: `adb logcat | grep Flutter`

---

## 📊 Cost Breakdown

| Service | Free Tier | Paid Option |
|---------|-----------|-------------|
| **Render Web** | 750 hrs/mo (with sleep) | $7/mo (always-on) |
| **Render PostgreSQL** | 1GB (90 day expiry) | $7/mo (10GB) |
| **Upstash Redis** | 256MB, 500K cmds | $10/mo (1GB) |
| **Android APK** | FREE ✅ | N/A |
| **Play Store** | $25 one-time | N/A |
| **App Store (iOS)** | $99/year | N/A |

**Total Monthly Cost: $0** (with free tiers)

---

## 🎯 Next Steps

1. ✅ Deploy backend to Render
2. ✅ Build and install Android APK
3. ✅ Test with demo data
4. ⚙️ Customize for your organization
5. 📱 Deploy to Play Store (optional)
6. 🍎 Build iOS version if needed

---

## 📞 Support & Resources

- **Render Docs**: https://docs.render.com/
- **Upstash Docs**: https://docs.upstash.com/
- **Flutter Docs**: https://docs.flutter.dev/
- **FastAPI Docs**: https://fastapi.tiangolo.com/

---

## 🎉 Success Criteria

You'll know deployment succeeded when:
- ✅ Backend health endpoint returns `{"status": "healthy"}`
- ✅ Mobile app can login with demo credentials
- ✅ You can create workers, mark attendance, generate payroll
- ✅ Offline mode works without internet
- ✅ Data syncs when back online

**Congratulations! Your EthioWorkforce system is now fully deployed on mobile! 🎊**
