# EthioWorkforce Web Demo Setup Guide

## Quick Start (Recommended)

Since you're in WSL, run these commands **directly in your WSL terminal**:

### 1. Complete Web Setup

```bash
cd /home/hnde/EthioWorkForce
bash setup_web_demo.sh
```

### 2. Start Backend (Terminal 1)

**Option A: Using Docker (Easiest)**
```bash
cd /home/hnde/EthioWorkForce
docker-compose up
```

**Option B: Manual Setup**
```bash
cd /home/hnde/EthioWorkForce/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python scripts/init_db.py  # Creates demo admin user
python run.py
```

Backend API will be at: `http://localhost:8000`
API Docs: `http://localhost:8000/api/docs`

### 3. Run Flutter Web (Terminal 2)

```bash
cd /home/hnde/EthioWorkForce/frontend
flutter run -d chrome --web-port 8080
```

Or open in Edge:
```bash
flutter run -d edge --web-port 8080
```

### 4. Login to Demo

- **URL**: `http://localhost:8080`
- **Username**: admin
- **Password**: admin123

## Production Build

To create a production-ready web build:

```bash
cd /home/hnde/EthioWorkForce/frontend

# Build for production
flutter build web --release

# Output will be in: frontend/build/web/
# Serve with any web server, e.g.:
cd build/web
python3 -m http.server 8080
```

## Troubleshooting

### If Chrome/Edge not detected:
```bash
flutter config --enable-web
flutter devices  # Should now show Chrome/Edge
```

### If build fails:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Database connection error:
Make sure PostgreSQL is running (via Docker or locally)

### CORS error in browser:
Update `backend/.env`:
```
CORS_ORIGINS=http://localhost:8080,http://localhost:*
```

Then restart the backend.

## Demo Features to Showcase

✅ **Dashboard** - View workforce overview  
✅ **Site Management** - Create/manage multiple sites  
✅ **Worker Management** - Add workers with photos  
✅ **Work Types** - Configure Daily Laborer vs Permanent Staff  
✅ **Attendance** - Dual calendar (Ethiopian & Gregorian)  
✅ **Payroll** - Automatic tax calculation (ERCA rules)  
✅ **Reports** - Export to Excel/PDF  
✅ **Offline Mode** - Works without internet (sync later)  

## Next Steps

### Create Demo Data

Create sample workers, sites, and attendance records:

```bash
cd /home/hnde/EthioWorkForce/backend
source venv/bin/activate
python scripts/create_demo_data.py  # (To be created)
```

### Deploy to Production

See `DEPLOYMENT.md` for production deployment instructions.

## Architecture

```
┌─────────────────┐      HTTP/REST      ┌─────────────────┐
│  Flutter Web    │ ◄─────────────────► │   FastAPI       │
│  (Port 8080)    │      JSON           │   (Port 8000)   │
└─────────────────┘                     └────────┬────────┘
        │                                        │
        │ IndexedDB                              │
        │ (Offline)                              │
        │                                ┌───────▼────────┐
        │                                │  PostgreSQL    │
        │                                │  (Port 5432)   │
        │                                └────────────────┘
        │                                        │
        │                                ┌───────▼────────┐
        │                                │     Redis      │
        └────────────────────────────────┤  (Port 6379)   │
                                         └────────────────┘
```

## Support

For issues, check:
1. Backend logs: `backend/logs/`
2. Browser console (F12)
3. Flutter error messages in terminal
