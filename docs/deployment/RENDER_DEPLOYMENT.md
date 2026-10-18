# Deploy to Render.com (Free) - Step by Step

**Time Required**: 20 minutes  
**Cost**: $0/month  
**Difficulty**: Easy

---

## Prerequisites

- [ ] GitHub account (free)
- [ ] Render account (free) - sign up at https://render.com
- [ ] Your code pushed to GitHub

---

## Step 1: Prepare Your Code (5 minutes)

### 1.1 Create `render.yaml` in project root

```yaml
databases:
  - name: ethioworkforce-db
    databaseName: ethioworkforce
    user: ethioworkforce_user
    plan: free

services:
  - type: web
    name: ethioworkforce-api
    runtime: python
    buildCommand: "cd backend && pip install -r requirements.txt && alembic upgrade head"
    startCommand: "cd backend && uvicorn app.main:app --host 0.0.0.0 --port $PORT"
    plan: free
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: ethioworkforce-db
          property: connectionString
      - key: SECRET_KEY
        generateValue: true
      - key: ENVIRONMENT
        value: production
      - key: DEBUG
        value: false
      - key: ALGORITHM
        value: HS256
      - key: ACCESS_TOKEN_EXPIRE_MINUTES
        value: 30
```

### 1.2 Update `backend/requirements.txt`

Make sure it includes:
```txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
alembic==1.13.1
psycopg2-binary==2.9.9
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
pydantic==2.5.3
pydantic-settings==2.1.0
```

### 1.3 Push to GitHub

```bash
git add .
git commit -m "Prepare for Render deployment"
git push origin main
```

---

## Step 2: Deploy on Render (10 minutes)

### 2.1 Create Render Account

1. Go to https://render.com
2. Click "Get Started"
3. Sign up with GitHub (easier)

### 2.2 Create PostgreSQL Database

1. Click "New +" → "PostgreSQL"
2. Settings:
   - **Name**: `ethioworkforce-db`
   - **Database**: `ethioworkforce`
   - **User**: `ethioworkforce_user`
   - **Region**: Choose closest to Ethiopia (Frankfurt or Mumbai)
   - **Instance Type**: **Free**
3. Click "Create Database"
4. Wait 2-3 minutes for provisioning
5. **Copy "Internal Database URL"** - you'll need this

### 2.3 Create Web Service

1. Click "New +" → "Web Service"
2. Connect your GitHub repository
3. Settings:
   - **Name**: `ethioworkforce-api`
   - **Region**: Same as database
   - **Branch**: `main`
   - **Root Directory**: Leave empty
   - **Runtime**: Python 3
   - **Build Command**: 
     ```bash
     cd backend && pip install -r requirements.txt && alembic upgrade head
     ```
   - **Start Command**:
     ```bash
     cd backend && uvicorn app.main:app --host 0.0.0.0 --port $PORT
     ```
   - **Instance Type**: **Free**

### 2.4 Add Environment Variables

Click "Advanced" → "Add Environment Variable":

```
DATABASE_URL = <paste Internal Database URL from step 2.2>
SECRET_KEY = <generate: openssl rand -hex 32>
ENVIRONMENT = production
DEBUG = false
ALGORITHM = HS256
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7
CORS_ORIGINS = ["*"]
```

### 2.5 Deploy

1. Click "Create Web Service"
2. Render will:
   - Clone your repo
   - Install dependencies
   - Run migrations
   - Start the server
3. **Wait 5-10 minutes** for first deploy
4. You'll see logs in real-time

---

## Step 3: Verify Deployment (2 minutes)

### 3.1 Get Your API URL

After deployment succeeds, you'll get a URL like:
```
https://ethioworkforce-api.onrender.com
```

### 3.2 Test Health Endpoint

```bash
curl https://ethioworkforce-api.onrender.com/health
```

Expected response:
```json
{"status":"healthy","service":"ethioworkforce-api"}
```

### 3.3 Access API Documentation

Open in browser:
```
https://ethioworkforce-api.onrender.com/api/docs
```

You should see the interactive API documentation (Swagger UI)!

---

## Step 4: Create Admin User (3 minutes)

### 4.1 Register First Admin

Using the API docs or curl:

```bash
curl -X POST https://ethioworkforce-api.onrender.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "email": "admin@yourcompany.com",
    "full_name": "System Administrator",
    "password": "ChangeThis123!",
    "role": "super_admin"
  }'
```

### 4.2 Test Login

```bash
curl -X POST https://ethioworkforce-api.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "ChangeThis123!"
  }'
```

You should get a token response!

---

## Step 5: Configure Mobile App (2 minutes)

### 5.1 Update Backend URL

**Option A**: In code (before building APK)

Edit `frontend/lib/core/network/dio_client.dart`:

```dart
static const String _baseUrl = "https://ethioworkforce-api.onrender.com/api/v1";
```

**Option B**: In app settings (after installing)

1. Open app
2. Go to Settings
3. Backend Configuration
4. Enter: `https://ethioworkforce-api.onrender.com/api/v1`
5. Save

### 5.2 Build and Install App

```bash
cd frontend
flutter build apk --release
```

Install `build/app/outputs/flutter-apk/app-release.apk` on your phone.

---

## 🎉 You're Done!

Your app is now deployed and running on Render's free tier!

---

## ⚙️ Post-Deployment Configuration

### Enable Auto-Deploy (Optional)

Render automatically deploys when you push to GitHub. To disable:
- Go to your service settings
- Uncheck "Auto-Deploy"

### Custom Domain (Optional, Free)

1. Go to service settings
2. "Custom Domains"
3. Add your domain
4. Update DNS records as instructed

### Set Up Uptime Monitoring (Free)

To prevent cold starts (server sleeping):

1. Go to https://uptimerobot.com (free)
2. Add new monitor:
   - **Type**: HTTP(s)
   - **URL**: `https://ethioworkforce-api.onrender.com/health`
   - **Interval**: 14 minutes
3. This pings your server every 14 minutes to keep it awake

---

## 🔍 Monitoring Your App

### View Logs

1. Go to Render dashboard
2. Click your service
3. "Logs" tab
4. Real-time log streaming

### View Metrics

1. Service dashboard
2. "Metrics" tab
3. See:
   - CPU usage
   - Memory usage
   - Request count
   - Response times

### Database Management

1. Go to database dashboard
2. "Info" tab has connection details
3. Connect with any PostgreSQL client:
   ```bash
   psql <External Database URL>
   ```

---

## 🚨 Troubleshooting

### Problem: Build Failed

**Check**:
- `requirements.txt` is correct
- Build command includes `cd backend`
- No syntax errors in Python code

**Solution**:
- Check logs in Render dashboard
- Fix errors and push to GitHub
- Render auto-redeploys

### Problem: Database Connection Error

**Check**:
- DATABASE_URL is set correctly
- Using "Internal Database URL" not "External"

**Solution**:
- Go to database dashboard
- Copy "Internal Database URL"
- Update environment variable
- Restart service

### Problem: 502 Bad Gateway

**Cause**: Server crashed or port mismatch

**Solution**:
- Check logs for errors
- Ensure start command uses `$PORT` variable
- Restart service

### Problem: Cold Starts (Slow First Request)

**Cause**: Free tier spins down after 15 min inactivity

**Solutions**:
- Accept 30s delay (normal for free tier)
- Set up UptimeRobot pings
- Upgrade to paid tier ($7/month, always running)

---

## 📊 Free Tier Limits

**Web Service**:
- ✅ 512 MB RAM
- ✅ 0.1 CPU
- ✅ 750 hours/month (enough for 24/7)
- ⚠️ Spins down after 15 min inactivity
- ⚠️ Shared IP

**PostgreSQL**:
- ✅ 256 MB RAM
- ✅ 1 GB storage
- ✅ Automatic backups
- ⚠️ Expires after 90 days (backup your data!)

**What happens after 90 days?**
- Database data will be deleted
- You can create a new free database
- **Solution**: Set calendar reminder to backup before day 85

---

## 💾 Backup Strategy on Free Tier

### Automated Weekly Backup

Create GitHub Action (`.github/workflows/backup.yml`):

```yaml
name: Weekly Backup

on:
  schedule:
    - cron: '0 2 * * 0'  # Every Sunday at 2 AM

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Backup Database
        run: |
          pg_dump ${{ secrets.DATABASE_URL }} > backup_$(date +%Y%m%d).sql
          # Upload to GitHub release or Google Drive
```

### Manual Backup

```bash
# Get External Database URL from Render dashboard
pg_dump "<External Database URL>" > backup.sql
```

---

## 🔄 Updating Your App

### Method 1: Auto-Deploy (Recommended)

```bash
# Make changes locally
git add .
git commit -m "Update feature X"
git push origin main

# Render automatically rebuilds and deploys!
```

### Method 2: Manual Deploy

1. Go to Render dashboard
2. Click "Manual Deploy"
3. Select branch
4. Deploy

---

## 💰 When to Upgrade

**Stay on Free Tier if**:
- < 200 workers
- < 1000 requests/day
- Can tolerate 30s cold starts
- Single organization

**Upgrade to Paid ($7/month) when**:
- Need 24/7 uptime (no cold starts)
- > 500 workers
- > 5000 requests/day
- Multiple organizations
- Need > 1 GB database

---

## 🎯 Next Steps

- [ ] Test all API endpoints
- [ ] Import initial data (sites, work types)
- [ ] Train users
- [ ] Set up backup reminders
- [ ] Monitor usage
- [ ] Collect feedback

---

## 📞 Support

**Render Support**:
- Docs: https://render.com/docs
- Community: https://community.render.com

**EthioWorkForce Support**:
- GitHub Issues: [your-repo]/issues
- Email: support@ethioworkforce.et

---

**Congratulations! Your app is live on the internet for FREE! 🎉**
