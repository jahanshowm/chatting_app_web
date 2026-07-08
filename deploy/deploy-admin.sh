#!/usr/bin/env bash
# Admin Web — Flutter 빌드 + 정적 파일 rsync (Apache/nginx/SSL 미포함)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${DEPLOY_CONFIG:-$ROOT/deploy/deploy.config}"

if [[ -f "$CONFIG" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG"
fi

REMOTE="${1:-${DEPLOY_SSH:-root@3.35.204.151}}"
REMOTE_WEB_DIR="${REMOTE_WEB_DIR:-/var/www/adminchat}"
ENV_BUILD="${ENV_BUILD_FILE:-$ROOT/.env.build.adminchat}"
DEPLOY_DOMAIN="${DEPLOY_DOMAIN:-adminchat.kr}"

echo "==> 빌드용 .env 적용 ($ENV_BUILD)"
cp "$ENV_BUILD" "$ROOT/.env"

if [[ "${SKIP_WEB_BUILD:-0}" != "1" ]]; then
  echo "==> Flutter Web 빌드 (API: ${API_BASE_URL:-https://adminchat.kr})"
  cd "$ROOT"
  flutter pub get
  flutter build web --release

  echo "==> 서버 업로드 ($REMOTE:$REMOTE_WEB_DIR)"
  ssh "$REMOTE" "mkdir -p $REMOTE_WEB_DIR"
  rsync -avz --delete "$ROOT/build/web/" "$REMOTE:$REMOTE_WEB_DIR/"
else
  echo "==> SKIP_WEB_BUILD=1 — Flutter 빌드·Web 업로드 생략"
fi

echo "==> 로컬 .env 복원 (development)"
cp "$ROOT/.env.development" "$ROOT/.env" 2>/dev/null || true

echo "==> 완료: https://$DEPLOY_DOMAIN"
echo ""
echo "배포 후 확인:"
echo "  curl -sI https://$DEPLOY_DOMAIN/ | head -1"
echo "  curl -s https://$DEPLOY_DOMAIN/api/health"
