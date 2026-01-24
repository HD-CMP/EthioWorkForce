#!/bin/bash

set -e

echo "========================================"
echo "EthioWorkForce Deployment Script"
echo "========================================"

DEPLOY_DIR="/opt/ethioworkforce"
APP_USER="www-data"
VENV_DIR="$DEPLOY_DIR/backend/venv"

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "Step 1/10: Creating application directory..."
mkdir -p $DEPLOY_DIR
cd $DEPLOY_DIR

echo "Step 2/10: Cloning repository..."
if [ -d "$DEPLOY_DIR/.git" ]; then
    echo "Repository exists, pulling latest changes..."
    git pull
else
    read -p "Enter repository URL: " REPO_URL
    git clone $REPO_URL .
fi

echo "Step 3/10: Setting up Python virtual environment..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "Step 4/10: Setting up environment variables..."
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo ""
    echo "IMPORTANT: Edit /opt/ethioworkforce/backend/.env with production values"
    echo "Required: DATABASE_URL, SECRET_KEY, CORS_ORIGINS"
    read -p "Press Enter to continue after editing .env..."
fi

echo "Step 5/10: Running database migrations..."
source venv/bin/activate
alembic upgrade head

echo "Step 6/10: Creating systemd service..."
cat > /etc/systemd/system/ethioworkforce.service << EOF
[Unit]
Description=EthioWorkForce API Server
After=network.target postgresql.service

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$DEPLOY_DIR/backend
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Step 7/10: Creating log directory..."
mkdir -p /var/log/ethioworkforce
chown -R $APP_USER:$APP_USER /var/log/ethioworkforce

echo "Step 8/10: Setting permissions..."
chown -R $APP_USER:$APP_USER $DEPLOY_DIR

echo "Step 9/10: Configuring Nginx..."
cat > /etc/nginx/sites-available/ethioworkforce << 'EOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static {
        alias /opt/ethioworkforce/backend/static;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ethioworkforce /etc/nginx/sites-enabled/
nginx -t

echo "Step 10/10: Starting services..."
systemctl daemon-reload
systemctl enable ethioworkforce
systemctl start ethioworkforce
systemctl restart nginx

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""
echo "Service status:"
systemctl status ethioworkforce --no-pager
echo ""
echo "API accessible at: http://$(hostname -I | awk '{print $1}'):8000"
echo "Health check: curl http://localhost:8000/health"
echo ""
echo "Next steps:"
echo "1. Configure SSL certificate (certbot)"
echo "2. Set up automated backups (crontab)"
echo "3. Configure firewall (ufw)"
echo "4. Test all endpoints"
echo ""
