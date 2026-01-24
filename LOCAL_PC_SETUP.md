# Local PC Setup Guide (PostgreSQL on Your Computer)

**Perfect For**: Running server on your own Windows/Linux PC  
**Cost**: $0 (uses your PC as server)  
**Setup Time**: 15 minutes

---

## Overview

Run the EthioWorkForce backend on your local PC with PostgreSQL. Your PC acts as the server, and phones connect to it via WiFi/local network.

**Advantages**:
- ✅ Full control of data (stays on your PC)
- ✅ No internet dependency after setup
- ✅ No monthly hosting costs
- ✅ Fast performance (local network)
- ✅ Support multiple phones/tablets

**Requirements**:
- Windows 10/11 or Linux (Ubuntu 20.04+)
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space
- WiFi/Local network

---

## Windows Setup (15 minutes)

### Step 1: Install PostgreSQL

1. **Download PostgreSQL 15**
   - Visit: https://www.postgresql.org/download/windows/
   - Download installer for Windows x86-64
   - Run installer

2. **During Installation**:
   - Port: `5432` (default)
   - Password: Choose strong password (remember this!)
   - Locale: Default
   - Install pgAdmin 4 (optional GUI tool)

3. **Verify Installation**:
   ```cmd
   psql --version
   ```

### Step 2: Create Database

1. **Open Command Prompt (Run as Administrator)**

2. **Login to PostgreSQL**:
   ```cmd
   psql -U postgres
   ```
   Enter your password

3. **Create Database**:
   ```sql
   CREATE DATABASE ethioworkforce;
   CREATE USER ethio_admin WITH PASSWORD 'YourStrongPassword123!';
   GRANT ALL PRIVILEGES ON DATABASE ethioworkforce TO ethio_admin;
   \q
   ```

### Step 3: Install Python & Dependencies

1. **Install Python 3.11**:
   - Visit: https://www.python.org/downloads/
   - Download Python 3.11 installer
   - **Check "Add Python to PATH"**
   - Install

2. **Verify Python**:
   ```cmd
   python --version
   python -m pip --version
   ```

3. **Navigate to Project**:
   ```cmd
   cd C:\path\to\EthioWorkForce\backend
   ```

4. **Create Virtual Environment**:
   ```cmd
   python -m venv venv
   venv\Scripts\activate
   ```

5. **Install Dependencies**:
   ```cmd
   pip install -r requirements.txt
   ```

### Step 4: Configure Environment

1. **Create `.env` file** in `backend/` folder:
   ```env
   # Database
   DATABASE_URL=postgresql://ethio_admin:YourStrongPassword123!@localhost:5432/ethioworkforce

   # Security
   SECRET_KEY=your-secret-key-generate-with-openssl
   ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=30
   REFRESH_TOKEN_EXPIRE_DAYS=7

   # Environment
   ENVIRONMENT=production
   DEBUG=false

   # CORS - Allow phones on local network
   CORS_ORIGINS=["http://localhost:3000","http://192.168.*.*"]
   ```

2. **Generate Secret Key**:
   ```cmd
   python -c "import secrets; print(secrets.token_hex(32))"
   ```
   Copy output to `SECRET_KEY` in `.env`

### Step 5: Initialize Database

```cmd
cd backend
venv\Scripts\activate
alembic upgrade head
```

### Step 6: Run the Server

1. **Start Backend**:
   ```cmd
   cd backend
   venv\Scripts\activate
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

2. **Find Your PC's IP Address**:
   ```cmd
   ipconfig
   ```
   Look for "IPv4 Address" under your WiFi adapter
   Example: `192.168.1.100`

3. **Test API**:
   Open browser: `http://192.168.1.100:8000/docs`
   You should see API documentation

### Step 7: Configure Phone App

1. **Connect Phone to Same WiFi** as your PC

2. **Open EthioWorkForce App**

3. **Go to Settings**:
   - Backend URL: `http://192.168.1.100:8000`
   - Enable "Auto Sync"
   - Test Connection (should show ✅ Connected)

4. **Login/Register**:
   - Create admin account
   - Start using!

---

## Linux (Ubuntu) Setup (10 minutes)

### Step 1: Install PostgreSQL

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

### Step 2: Create Database

```bash
sudo -u postgres psql
```

```sql
CREATE DATABASE ethioworkforce;
CREATE USER ethio_admin WITH PASSWORD 'YourStrongPassword123!';
GRANT ALL PRIVILEGES ON DATABASE ethioworkforce TO ethio_admin;
\q
```

### Step 3: Install Python Dependencies

```bash
cd ~/EthioWorkForce/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Step 4: Configure Environment

```bash
cd ~/EthioWorkForce/backend
nano .env
```

Paste:
```env
DATABASE_URL=postgresql://ethio_admin:YourStrongPassword123!@localhost:5432/ethioworkforce
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
ENVIRONMENT=production
DEBUG=false
CORS_ORIGINS=["http://localhost:3000","http://192.168.*.*"]
```

### Step 5: Initialize Database

```bash
cd ~/EthioWorkForce/backend
source venv/bin/activate
alembic upgrade head
```

### Step 6: Run Server

```bash
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Step 7: Find IP Address

```bash
hostname -I
```

Example output: `192.168.1.100`

Configure phone app with: `http://192.168.1.100:8000`

---

## Run as Windows Service (Auto-Start)

### Option 1: Using NSSM (Recommended)

1. **Download NSSM**:
   - Visit: https://nssm.cc/download
   - Extract to `C:\nssm`

2. **Install Service**:
   ```cmd
   cd C:\nssm\win64
   nssm install EthioWorkForce
   ```

3. **Configure Service**:
   - Path: `C:\path\to\EthioWorkForce\backend\venv\Scripts\python.exe`
   - Startup directory: `C:\path\to\EthioWorkForce\backend`
   - Arguments: `-m uvicorn app.main:app --host 0.0.0.0 --port 8000`

4. **Start Service**:
   ```cmd
   nssm start EthioWorkForce
   ```

5. **Set Auto-Start**:
   - Open Services (Win + R, type `services.msc`)
   - Find "EthioWorkForce"
   - Properties → Startup type: **Automatic**

### Option 2: Task Scheduler

1. **Open Task Scheduler**

2. **Create Task**:
   - Name: EthioWorkForce Backend
   - Trigger: At system startup
   - Action: Start program
     - Program: `C:\path\to\backend\venv\Scripts\python.exe`
     - Arguments: `-m uvicorn app.main:app --host 0.0.0.0 --port 8000`
     - Start in: `C:\path\to\backend`

---

## Run as Linux Service (Auto-Start)

```bash
sudo nano /etc/systemd/system/ethioworkforce.service
```

Paste:
```ini
[Unit]
Description=EthioWorkForce Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=your-username
WorkingDirectory=/home/your-username/EthioWorkForce/backend
Environment="PATH=/home/your-username/EthioWorkForce/backend/venv/bin"
ExecStart=/home/your-username/EthioWorkForce/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

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

---

## Network Configuration

### Same WiFi Network (Simplest)

- PC and phones on same WiFi
- Phones use PC's local IP: `http://192.168.1.100:8000`
- Works without internet

### Allow Through Firewall

**Windows**:
```cmd
netsh advfirewall firewall add rule name="EthioWorkForce" dir=in action=allow protocol=TCP localport=8000
```

**Linux**:
```bash
sudo ufw allow 8000/tcp
```

### Access from Outside Network (Advanced)

**Option A: Port Forwarding** (if you have router access):
1. Login to router admin panel
2. Forward port 8000 to your PC's local IP
3. Find your public IP: https://whatismyip.com
4. Access from anywhere: `http://your-public-ip:8000`

**Option B: Ngrok** (easiest for testing):
```bash
# Download ngrok from https://ngrok.com
ngrok http 8000
```
Use the HTTPS URL provided (e.g., `https://abc123.ngrok.io`)

---

## Backup Strategy

### Automated Daily Backup (Windows)

Create `backup.bat`:
```batch
@echo off
set BACKUP_DIR=C:\Backups\EthioWorkForce
set DATE=%date:~-4,4%%date:~-10,2%%date:~-7,2%

mkdir %BACKUP_DIR%\%DATE%

pg_dump -U ethio_admin -h localhost ethioworkforce > %BACKUP_DIR%\%DATE%\database.sql

xcopy /E /I /Y C:\path\to\EthioWorkForce\backend\uploads %BACKUP_DIR%\%DATE%\uploads

echo Backup completed: %DATE%
```

Schedule with Task Scheduler (daily at 2 AM).

### Automated Daily Backup (Linux)

Use the existing script:
```bash
sudo cp ~/EthioWorkForce/backend/scripts/backup_database.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup_database.sh

crontab -e
```

Add:
```
0 2 * * * /usr/local/bin/backup_database.sh >> /var/log/ethioworkforce_backup.log 2>&1
```

---

## Performance Tuning

### PostgreSQL Optimization

Edit `postgresql.conf`:

**Windows**: `C:\Program Files\PostgreSQL\15\data\postgresql.conf`  
**Linux**: `/etc/postgresql/15/main/postgresql.conf`

```ini
shared_buffers = 256MB          # 25% of RAM
effective_cache_size = 1GB      # 50% of RAM
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
work_mem = 4MB
```

Restart PostgreSQL:
```cmd
# Windows
net stop postgresql-x64-15
net start postgresql-x64-15

# Linux
sudo systemctl restart postgresql
```

---

## Monitoring

### Check Server Status

**Windows**:
```cmd
curl http://localhost:8000/health
```

**Linux**:
```bash
curl http://localhost:8000/health
systemctl status ethioworkforce
```

### View Logs

**Windows** (if using NSSM):
- Logs: `C:\path\to\backend\nssm.log`

**Linux**:
```bash
sudo journalctl -u ethioworkforce -f
```

### Database Monitoring

```bash
# Connect to database
psql -U ethio_admin -d ethioworkforce

# Check database size
\l+

# Check table sizes
\dt+

# Check active connections
SELECT * FROM pg_stat_activity;
```

---

## Troubleshooting

### Can't Connect from Phone

1. **Check PC firewall** - allow port 8000
2. **Verify same WiFi network**
3. **Test from PC browser first**: `http://localhost:8000/docs`
4. **Ping PC from phone**: Use Network Analyzer app
5. **Check CORS settings** in `.env`

### Server Won't Start

1. **Check port 8000 not in use**:
   ```cmd
   netstat -ano | findstr :8000
   ```

2. **Verify database running**:
   ```cmd
   # Windows
   net start postgresql-x64-15
   
   # Linux
   sudo systemctl status postgresql
   ```

3. **Check database credentials** in `.env`

### Slow Performance

1. **Optimize PostgreSQL** (see Performance Tuning above)
2. **Increase workers**: `uvicorn app.main:app --workers 4`
3. **Check disk space**: `df -h` (Linux) or `dir` (Windows)
4. **Monitor RAM usage**: Task Manager (Windows) or `htop` (Linux)

---

## Security Recommendations

### For Production Use

1. **Strong passwords** (database, admin account)
2. **Enable HTTPS** with self-signed certificate:
   ```bash
   # Generate certificate
   openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365
   
   # Run with HTTPS
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile=key.pem --ssl-certfile=cert.pem
   ```

3. **Firewall rules** - only allow trusted IPs
4. **Regular backups** - automated daily
5. **Update regularly**: `pip install --upgrade -r requirements.txt`

---

## Cost Comparison

| Deployment | Setup | Monthly | Pros | Cons |
|------------|-------|---------|------|------|
| **Local PC** | 15 min | **$0** | Full control, fast, offline | PC must stay on |
| **Phone Only** | 5 min | **$0** | Ultra simple, portable | Single device |
| **Render.com** | 20 min | **$0** | Cloud access, no PC | 15min spin-down |
| **VPS** | 30 min | **$5-10** | Always on, public IP | Monthly cost |

---

## Next Steps

1. ✅ Server running on PC
2. ✅ Phones connected via WiFi
3. 📱 Install mobile app on all phones
4. 👥 Create user accounts for staff
5. 🏗️ Add sites and work types
6. 👷 Add workers
7. 📊 Start marking attendance
8. 💰 Generate payroll at month-end

**Your local server is ready! All data stays on your PC. No internet or cloud needed.**
