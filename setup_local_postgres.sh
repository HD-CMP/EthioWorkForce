#!/bin/bash

set -e

echo "========================================"
echo "EthioWorkForce - Local PC Setup"
echo "PostgreSQL + Backend on Windows/WSL"
echo "========================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"

echo "Step 1/7: Checking PostgreSQL installation..."
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL not found. Installing..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    else
        echo "Please install PostgreSQL manually from:"
        echo "https://www.postgresql.org/download/"
        exit 1
    fi
else
    echo "✓ PostgreSQL is installed"
fi

echo ""
echo "Step 2/7: Creating database..."
DB_NAME="ethioworkforce"
DB_USER="ethioworkforce_user"
DB_PASS="ethioworkforce_pass_2024"

sudo -u postgres psql << EOF
SELECT 'CREATE DATABASE $DB_NAME' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$DB_USER') THEN
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
    END IF;
END
\$\$;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\q
EOF

echo "✓ Database created: $DB_NAME"
echo "✓ User created: $DB_USER"

echo ""
echo "Step 3/7: Setting up Python virtual environment..."
cd "$BACKEND_DIR"

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "✓ Virtual environment ready"

echo ""
echo "Step 4/7: Configuring environment variables..."
cat > .env << EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
ENVIRONMENT=production
DEBUG=false
CORS_ORIGINS=["*"]
LOG_LEVEL=INFO
UPLOAD_DIR=uploads
MAX_UPLOAD_SIZE=10485760
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
DB_POOL_TIMEOUT=30
DB_POOL_RECYCLE=3600
EOF

echo "✓ Environment configured"

echo ""
echo "Step 5/7: Running database migrations..."
alembic upgrade head
echo "✓ Database schema created"

echo ""
echo "Step 6/7: Creating uploads directory..."
mkdir -p uploads
mkdir -p logs
echo "✓ Directories created"

echo ""
echo "Step 7/7: Testing server..."
timeout 5s uvicorn app.main:app --host 0.0.0.0 --port 8000 || true

echo ""
echo "========================================"
echo "✅ LOCAL SETUP COMPLETE!"
echo "========================================"
echo ""
echo "Database Connection:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASS"
echo ""
echo "To start the server:"
echo "  cd backend"
echo "  source venv/bin/activate"
echo "  uvicorn app.main:app --host 0.0.0.0 --port 8000"
echo ""
echo "API will be available at:"
echo "  http://localhost:8000"
echo "  http://localhost:8000/api/docs (API documentation)"
echo "  http://localhost:8000/health (health check)"
echo ""
echo "Configure your mobile app to use:"
echo "  Backend URL: http://YOUR_PC_IP:8000/api/v1"
echo "  (Replace YOUR_PC_IP with your PC's local IP address)"
echo ""
