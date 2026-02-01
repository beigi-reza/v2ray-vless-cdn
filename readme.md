# V2Ray Server with Vless + WS + TLS + CDN

This setup creates a V2Ray server with:
- **Vless** protocol
- **WebSocket** transport
- **TLS** encryption
- **CDN** support (Cloudflare compatible)
- **Nginx** reverse proxy for camouflage

## Prerequisites

1. A VPS/Server with Ubuntu/Debian
2. A domain name
3. Domain DNS pointing to your server IP
4. Root access

## Quick Start

### Automated Setup (Recommended)

```bash
sudo ./setup.sh
```

The script will:
1. Install Docker and dependencies
2. Ask for your domain name
3. Generate a UUID
4. Obtain SSL certificate via Let's Encrypt
5. Configure and start services
6. Display your connection information

### Manual Setup

If you prefer manual setup:

#### 1. Update Configuration

Edit `v2ray/config.json`:
- Replace `your-domain.com` with your domain
- Replace `YOUR-UUID-HERE` with a UUID (generate with `uuidgen`)

Edit `nginx/nginx.conf`:
- Replace `your-domain.com` with your domain

#### 2. Get SSL Certificate

```bash
sudo certbot certonly --standalone -d your-domain.com
```

#### 3. Copy Certificates

```bash
mkdir -p v2ray/certs
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem v2ray/certs/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem v2ray/certs/
sudo chmod 644 v2ray/certs/*
```

#### 4. Start Services

```bash
docker-compose up -d
```

## CDN Setup (Cloudflare)

1. Log in to Cloudflare
2. Add your domain
3. Create an A record:
   - Name: `@` (or subdomain)
   - Content: Your server IP
   - Proxy status: **Proxied** (orange cloud)
4. SSL/TLS settings:
   - Encryption mode: **Full**
   - Minimum TLS: 1.2
5. Enable **WebSockets** in Network settings

## Client Configuration

Use these settings in your V2Ray client:

```
Address: your-domain.com
Port: 443
UUID: [your-generated-uuid]
Protocol: Vless
Network: WebSocket
Path: /vmessws
TLS: Enabled
ALPN: h2,http/1.1
```

### Connection String Format

```
vless://[UUID]@[DOMAIN]:443?encryption=none&security=tls&type=ws&host=[DOMAIN]&path=%2Fvmessws#V2Ray-Server
```

## Management Commands

### View Logs
```bash
docker-compose logs -f
docker-compose logs -f v2ray
docker-compose logs -f nginx
```

### Restart Services
```bash
docker-compose restart
```

### Stop Services
```bash
docker-compose down
```

### Update V2Ray
```bash
docker-compose pull
docker-compose up -d
```

### Check Status
```bash
docker-compose ps
```

## Directory Structure

```
.
├── docker-compose.yml
├── setup.sh
├── v2ray/
│   ├── config.json
│   └── certs/
│       ├── fullchain.pem
│       └── privkey.pem
└── nginx/
    ├── nginx.conf
    └── html/
        └── index.html
```

## Security Recommendations

1. **Change WebSocket Path**: Edit the `/vmessws` path in both `config.json` and `nginx.conf`
2. **Firewall**: Only allow ports 80, 443, and SSH
   ```bash
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw allow 22/tcp
   ufw enable
   ```
3. **Regular Updates**: Keep Docker images and system updated
4. **Monitor Logs**: Regularly check for suspicious activity

## Troubleshooting

### Certificate Issues
```bash
# Renew certificate manually
sudo certbot renew --force-renewal
# Copy new certificates
sudo cp /etc/letsencrypt/live/your-domain.com/*.pem v2ray/certs/
sudo chmod 644 v2ray/certs/*
docker-compose restart
```

### Connection Failed
1. Check if services are running: `docker-compose ps`
2. Verify firewall rules: `ufw status`
3. Check DNS resolution: `nslookup your-domain.com`
4. View logs: `docker-compose logs`

### CDN Issues
- Ensure Cloudflare SSL mode is set to **Full**
- Verify WebSocket is enabled in Cloudflare
- Check if orange cloud is enabled for DNS record

## Performance Tuning

Edit `v2ray/config.json` to adjust:
- `loglevel`: Set to `"none"` for better performance
- Add routing rules for specific regions
- Configure DNS settings for faster resolution

## License

This configuration is provided as-is for educational purposes.

## Disclaimer

Ensure compliance with local laws and regulations when using proxy services.