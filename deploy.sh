#!/bin/bash
set -e

echo "=== 明信片设计器 一键部署 ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Build Flutter web (if source exists)
if [ -f "pubspec.yaml" ] && command -v flutter &> /dev/null; then
    echo "[1/4] Building Flutter web..."
    flutter build web
    rm -rf backend/static/app
    cp -r build/web backend/static/app
    echo "       Flutter web build complete."
else
    echo "[1/4] Skipping Flutter build (no Flutter SDK or source)."
    if [ ! -d "backend/static/app" ]; then
        echo "       ERROR: backend/static/app/ not found. Please build Flutter web first."
        exit 1
    fi
fi

# 2. Ensure data directories exist
mkdir -p data backend/static/cards
echo "[2/4] Data directories ready."

# 3. Build Docker image
echo "[3/4] Building Docker image..."
docker compose build

# 4. Start
echo "[4/4] Starting services..."
docker compose up -d

echo ""
echo "=== 部署完成 ==="
echo "访问地址: https://postcard.hn.takin.cc"
echo "管理后台: https://postcard.hn.takin.cc/admin"
echo "默认账号: admin / postcard2024"
