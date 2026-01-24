#!/bin/bash

set -e

echo "========================================"
echo "SSL Certificate Setup (Let's Encrypt)"
echo "========================================"

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

read -p "Enter your domain name (e.g., api.ethioworkforce.com): " DOMAIN
read -p "Enter your email address: " EMAIL

echo "Step 1/4: Installing Certbot..."
apt update
apt install -y certbot python3-certbot-nginx

echo "Step 2/4: Obtaining SSL certificate..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "Step 3/4: Testing certificate renewal..."
certbot renew --dry-run

echo "Step 4/4: Setting up auto-renewal..."
echo "0 0,12 * * * root certbot renew --quiet" >> /etc/crontab

echo ""
echo "========================================"
echo "SSL Setup Complete!"
echo "========================================"
echo "Your site is now accessible via HTTPS at: https://$DOMAIN"
echo "Certificate auto-renewal configured"
