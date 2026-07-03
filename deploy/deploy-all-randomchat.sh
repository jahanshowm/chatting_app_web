#!/usr/bin/env bash
set -euo pipefail

# randomchat.kr 운영 전체 배포: Backend(API) → Admin Web
# 사용: ./deploy/deploy-all-randomchat.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_ROOT="$(cd "$ROOT/../randomchat_back" && pwd)"

echo "========================================"
echo " randomchat.kr 운영 전체 배포"
echo "========================================"

echo ""
echo "[1/2] Backend + migration (/home/users/randomchat/www)"
export DEPLOY_CONFIG="$BACKEND_ROOT/deploy/deploy.config.production"
"$BACKEND_ROOT/deploy/deploy-production.sh"

echo ""
echo "[2/2] Admin Web (/var/www/randomchat)"
export DEPLOY_CONFIG="$ROOT/deploy/deploy.config.randomchat"
"$ROOT/deploy/deploy-admin.sh"

echo ""
echo "========================================"
echo " 배포 완료: https://randomchat.kr"
echo "  API: https://randomchat.kr/api/health"
echo "========================================"
