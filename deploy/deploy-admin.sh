#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/deploy/deploy.config"

if [[ -f "$CONFIG" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG"
fi

REMOTE="${1:-${DEPLOY_SSH:-ubuntu@13.209.176.251}}"
REMOTE_WEB_DIR="${REMOTE_WEB_DIR:-/var/www/adminchat}"

echo "==> 프로덕션 .env 적용"
cp "$ROOT/.env.production" "$ROOT/.env"

echo "==> Flutter Web 빌드 (API: ${API_BASE_URL:-https://adminchat.kr})"
cd "$ROOT"
flutter pub get
flutter build web --release

echo "==> 서버 업로드 ($REMOTE:$REMOTE_WEB_DIR)"
ssh "$REMOTE" "sudo mkdir -p $REMOTE_WEB_DIR && sudo chown -R \$(whoami):\$(whoami) $REMOTE_WEB_DIR"
rsync -avz --delete "$ROOT/build/web/" "$REMOTE:$REMOTE_WEB_DIR/"

echo "==> nginx 설정"
scp "$ROOT/deploy/nginx/adminchat.kr.conf" "$REMOTE:/tmp/adminchat.kr.conf"
ssh "$REMOTE" "sudo cp /tmp/adminchat.kr.conf /etc/nginx/sites-available/adminchat.kr && \
  sudo ln -sf /etc/nginx/sites-available/adminchat.kr /etc/nginx/sites-enabled/adminchat.kr && \
  sudo nginx -t && sudo systemctl reload nginx"

echo "==> 로컬 .env 복원 (development)"
cp "$ROOT/.env.development" "$ROOT/.env" 2>/dev/null || true

echo "==> 완료: https://${DEPLOY_DOMAIN:-adminchat.kr}"
