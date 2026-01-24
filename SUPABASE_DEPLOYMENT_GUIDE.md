# 🚀 Complete Free Deployment Guide - Supabase + Render + GitHub Actions

**Total Cost: $0/month | No Credit Card Required**

---

## 📋 What We're Deploying

1. **Supabase** → PostgreSQL Database (500MB free)
2. **Render.com** → FastAPI Backend (512MB RAM free)
3. **GitHub Actions** → Automated CI/CD (2000 min/month free)
4. **GitHub Releases** → Mobile APK distribution

---

## ⚡ STEP 1: Create Supabase Account & Database

### 1.1 Sign Up (No Credit Card Needed)

1. Go to https://supabase.com
2. Click **"Start your project"**
3. Sign up with GitHub (easiest) or email
4. Verify your email

### 1.2 Create New Project

1. Click **"New Project"**
2. Fill in:
   - **Name**: `ethioworkforce`
   - **Database Password**: Generate strong password (SAVE THIS!)
   - **Region**: Choose closest to Ethiopia (e.g., `eu-central-1` or `ap-southeast-1`)
   - **Pricing Plan**: **Free** (already selected)
3. Click **"Create new project"**
4. Wait 2-3 minutes for setup

### 1.3 Get Database Connection String

1. In Supabase Dashboard → **Settings** (left sidebar)
2. Click **"Database"**
3. Scroll to **"Connection string"** section
4. Select **"URI"** tab
5. Copy the connection string (looks like this):

```
postgresql://postgres:[YOUR-PASSWORD]@db.abc123xyz.supabase.co:5432/postgres
```

6. Replace `[YOUR-PASSWORD]` with the database password you created
7. **SAVE THIS - YOU'LL NEED IT!**

---

## ⚡ STEP 2: Create Render.com Account & Web Service

### 2.1 Sign Up (No Credit Card Needed)

1. Go to https://render.com
2. Click **"Get Started"**
3. Sign up with GitHub (recommended - allows auto-deploy)
4. Authorize Render to access your GitHub

### 2.2 Create Web Service

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository:
   - If not connected, click **"Connect account"**
   - Find and select your **EthioWorkForce** repository
   - Click **"Connect"**

3. Configure the service:
   - **Name**: `ethioworkforce-api` (or your choice)
   - **Region**: Choose free region (e.g., `Frankfurt` or `Singapore`)
   - **Branch**: `main` (or your default branch)
   - **Root Directory**: `backend`
   - **Runtime**: **Python 3**
   - **Build Command**: 
     ```
     pip install -r requirements.txt
     ```
   - **Start Command**:
     ```
     uvicorn app.main:app --host 0.0.0.0 --port $PORT
     ```
   - **Instance Type**: **Free** (already selected)

4. Click **"Advanced"** to add environment variables

### 2.3 Add Environment Variables

Click **"Add Environment Variable"** for each:

| Key | Value | Note |
|-----|-------|------|
| `DATABASE_URL` | `postgresql://postgres:...` | Paste Supabase connection string |
| `SECRET_KEY` | (generate 32+ random chars) | Use: `openssl rand -hex 32` |
| `REDIS_URL` | `redis://red-xxxxx.render.com:6379` | Add Redis service first (see below) |
| `CELERY_BROKER_URL` | Same as REDIS_URL + `/1` | |
| `CELERY_RESULT_BACKEND` | Same as REDIS_URL + `/2` | |
| `CORS_ORIGINS` | `*` | Allows mobile app to connect |
| `ENVIRONMENT` | `production` | |

### 2.4 Create Free Redis Service (For Celery)

1. In Render Dashboard → **"New +"** → **"Redis"**
2. **Name**: `ethioworkforce-redis`
3. **Plan**: **Free** (25MB)
4. Click **"Create Redis"**
5. Copy the **Internal Redis URL** (looks like `redis://red-xxxxx:6379`)
6. Add it to your Web Service environment variables above

### 2.5 Deploy Backend

1. Click **"Create Web Service"**
2. Render will automatically build and deploy
3. Wait 5-10 minutes
4. Your API will be live at: `https://ethioworkforce-api.onrender.com`

---

## ⚡ STEP 3: Initialize Database

### 3.1 Run Migrations

1. In Render Dashboard → Select your **Web Service**
2. Go to **"Shell"** tab (top right)
3. Run these commands:

```bash
cd backend

# Run database migrations
alembic upgrade head

# Initialize with demo data (admin user, sites, work types)
python scripts/init_db.py
```

### 3.2 Verify Database

Check if tables were created:

1. Go to Supabase Dashboard
2. Click **"Table Editor"** (left sidebar)
3. You should see tables: `users`, `workers`, `attendances`, `payrolls`, etc.

---

## ⚡ STEP 4: Configure GitHub Secrets for Auto-Deploy

### 4.1 Get Render API Key

1. In Render Dashboard → Click your profile (top right)
2. Go to **"Account Settings"**
3. Click **"API Keys"** (left sidebar)
4. Click **"Create API Key"**
5. **Name**: `GitHub Actions Deploy`
6. Copy the API key (starts with `rnd_...`)

### 4.2 Get Render Service ID

1. Go to your **Web Service** dashboard
2. Look at the URL - it will be like:
   ```
   https://dashboard.render.com/web/srv-xxxxxxxxxxxx
   ```
3. Copy the `srv-xxxxxxxxxxxx` part (that's your Service ID)

### 4.3 Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **"Settings"** → **"Secrets and variables"** → **"Actions"**
3. Click **"New repository secret"** for each:

| Secret Name | Value |
|-------------|-------|
| `RENDER_API_KEY` | Your Render API key (`rnd_...`) |
| `RENDER_SERVICE_ID` | Your service ID (`srv-...`) |

---

## ⚡ STEP 5: Test Automated Deployment

### 5.1 Make a Small Change

Edit any file in `backend/` folder (e.g., add a comment)

### 5.2 Push to GitHub

```bash
git add .
git commit -m "test: trigger auto-deployment"
git push origin main
```

### 5.3 Watch GitHub Actions

1. Go to your GitHub repo
2. Click **"Actions"** tab
3. You'll see **"Deploy Backend to Render"** workflow running
4. Wait for it to complete (green checkmark)

### 5.4 Verify Deployment

1. In Render Dashboard, go to **"Logs"** tab
2. Watch the deployment progress
3. Once complete, visit:
   ```
   https://YOUR-SERVICE-NAME.onrender.com/health
   ```
4. You should see: `{"status":"healthy","service":"ethioworkforce-api"}`

---

## ⚡ STEP 6: Build Mobile APK

### 6.1 Create a Git Tag

GitHub Actions will auto-build APK when you push a tag:

```bash
git tag -a v1.0.0 -m "First production release"
git push origin v1.0.0
```

### 6.2 Download APK

1. Go to GitHub repo → **"Actions"** tab
2. Find **"Build and Release APK"** workflow
3. Wait for completion (~10 minutes)
4. Go to **"Releases"** tab
5. Download `app-arm64-v8a-release.apk`

---

## ⚡ STEP 7: Configure Mobile App

### 7.1 Install APK on Phone

1. Transfer APK to your Android phone
2. Enable **"Install from Unknown Sources"**
3. Install the app

### 7.2 Set Backend URL

1. Open **EthioWorkforce** app
2. Go to **Settings** → **Backend Configuration**
3. Enter:
   ```
   https://YOUR-SERVICE-NAME.onrender.com/api/v1
   ```
4. Click **"Save"**

### 7.3 Login

**Default Admin Credentials:**
- Username: `admin`
- Password: `admin123`

---

## 🎊 YOU'RE DONE!

### Your Free Infrastructure:

✅ **Database**: Supabase PostgreSQL (500MB)  
✅ **Backend API**: Render (512MB RAM, sleeps after 15 min)  
✅ **Redis Cache**: Render Redis (25MB)  
✅ **CI/CD**: GitHub Actions (2000 min/month)  
✅ **APK Distribution**: GitHub Releases

### Important Notes:

⚠️ **Free tier limitations:**
- Render backend **sleeps after 15 minutes** of inactivity
- First request after sleep takes ~30 seconds (cold start)
- Supabase has 500MB database storage limit
- Redis has 25MB limit

💡 **To prevent sleep** (optional $7/month):
- Upgrade Render to Starter plan
- Backend stays awake 24/7

---

## 🔧 Troubleshooting

### Backend Not Responding
```bash
# Wake up backend by visiting health endpoint
curl https://YOUR-SERVICE-NAME.onrender.com/health
```

### Database Connection Error
- Check if DATABASE_URL in Render matches Supabase connection string
- Verify Supabase database password is correct
- Check if database migrations ran successfully

### GitHub Actions Failing
- Verify secrets are added correctly (RENDER_API_KEY, RENDER_SERVICE_ID)
- Check GitHub Actions logs for specific errors

### Mobile App Can't Connect
- Verify backend URL in app settings
- Check if backend is awake (visit /health endpoint)
- Enable offline mode in app if testing locally

---

## 📚 Next Steps

1. **Change admin password** in production
2. **Add more users** via registration workflow
3. **Test offline mode** on mobile app
4. **Set up monitoring** (Render dashboard)
5. **Configure automatic backups** (Supabase dashboard)

---

**Need Help?** Check existing documentation:
- `QUICK_START.md` - Quick deployment overview
- `HIERARCHICAL_PERMISSIONS_IMPLEMENTATION.md` - User roles
- `SECURITY_SPECIFICATION.md` - Security features
- `TESTING_STRATEGY.md` - Testing guide

**Happy Deploying! 🚀**
