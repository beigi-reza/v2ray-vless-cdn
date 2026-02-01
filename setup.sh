#!/bin/bash

# V2Ray Server Setup Script
# This script helps you set up V2Ray with Vless + WS + TLS + CDN

set -e

echo "=================================="
echo "V2Ray Server Setup"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Install dependencies
echo "[1/7] Installing dependencies..."
apt-get update
apt-get install -y docker.io docker-compose certbot

# Start Docker service
systemctl start docker
systemctl enable docker

# Get domain name
echo ""
echo "[2/7] Domain Configuration"
read -p "Enter your domain name (e.g., example.com): " DOMAIN

# Generate UUID
echo ""
echo "[3/7] Generating UUID..."
UUID=$(cat /proc/sys/kernel/random/uuid)
echo "Generated UUID: $UUID"

# Update configuration files
echo ""
echo "[4/7] Updating configuration files..."
sed -i "s/your-domain.com/$DOMAIN/g" v2ray/config.json
sed -i "s/your-domain.com/$DOMAIN/g" nginx/nginx.conf
sed -i "s/YOUR-UUID-HERE/$UUID/g" v2ray/config.json

# Get SSL certificate
echo ""
echo "[5/7] Obtaining SSL certificate..."
echo "Make sure your domain $DOMAIN points to this server's IP address!"
read -p "Press Enter to continue..."

certbot certonly --standalone -d $DOMAIN --agree-tos --register-unsafely-without-email

# Create certificate directory and copy certs
mkdir -p v2ray/certs
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem v2ray/certs/
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem v2ray/certs/
chmod 644 v2ray/certs/*

# Start services
echo ""
echo "[6/7] Starting services..."
docker compose up -d

# Display configuration
echo ""
echo "=================================="
echo "[7/7] Setup Complete!"
echo "=================================="
echo ""
echo "V2Ray Server Information:"
echo "------------------------"
echo "Address: $DOMAIN"
echo "Port: 443"
echo "UUID: $UUID"
echo "Protocol: Vless"
echo "Network: WebSocket"
echo "Path: /vmessws"
echo "TLS: Enabled"
echo "ALPN: h2,http/1.1"
echo ""
echo "For CDN (Cloudflare):"
echo "1. Add your domain to Cloudflare"
echo "2. Set DNS record: A record pointing to your server IP"
echo "3. Enable 'Proxy' (orange cloud)"
echo "4. SSL/TLS mode: Full"
echo "5. Use the above configuration in your client"
echo ""
echo "Client connection string:"
echo "vless://$UUID@$DOMAIN:443?encryption=none&security=tls&type=ws&host=$DOMAIN&path=%2Fvmessws#V2Ray-Server"
echo ""
echo "=================================="

# Setup auto-renewal for certificate
echo ""
echo "Setting up automatic SSL certificate renewal..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $(pwd)/v2ray/certs/ && cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $(pwd)/v2ray/certs/ && docker-compose restart v2ray nginx") | crontab -

echo "SSL certificate will auto-renew daily at 3 AM"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
echo "To restart: docker-compose restart"
