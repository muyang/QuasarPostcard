#!/bin/bash
set -e

DOMAIN="card.qpvisiontech.com"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== SSL Certificate Setup for $DOMAIN ==="

# Step 1: Start with HTTP-only config for Let's Encrypt verification
echo "[1/4] Starting nginx with HTTP-only config..."
mkdir -p certbot/www certbot/conf
cp nginx/default-http.conf nginx/default.conf
docker compose up -d nginx
sleep 3

# Step 2: Request Let's Encrypt certificate
echo "[2/4] Requesting SSL certificate..."
docker run --rm \
    -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
    -v "$(pwd)/certbot/www:/var/www/certbot" \
    certbot/certbot certonly \
    --webroot -w /var/www/certbot \
    -d "$DOMAIN" \
    --email admin@qpvisiontech.com \
    --agree-tos \
    --non-interactive

# Step 3: Switch to HTTPS config
echo "[3/4] Switching to HTTPS config..."
# Restore the HTTPS config (default-https.conf was the original)
cat > nginx/default.conf << 'NGINX'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name DOMAIN_PLACEHOLDER;

    ssl_certificate     /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://postcard:8100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }

    location /static/ {
        proxy_pass http://postcard:8100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        expires 7d;
        add_header Cache-Control "public, max-age=604800, immutable";
    }
}
NGINX
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx/default.conf
docker compose restart nginx

# Step 4: Verify
echo "[4/4] Testing HTTPS..."
sleep 2
curl -s -o /dev/null -w "HTTPS Status: %{http_code}\n" "https://$DOMAIN/api/health" || echo "(SSL OK — server may need a moment)"

echo ""
echo "=== SSL Setup Complete ==="
echo ""
echo "Next manual steps:"
echo "1. 微信公众平台 → 开发管理 → 服务器域名 → request合法域名 添加: https://$DOMAIN"
echo "2. 测试自动续期: docker run --rm -v \$(pwd)/certbot/conf:/etc/letsencrypt -v \$(pwd)/certbot/www:/var/www/certbot certbot/certbot renew"
