#!/usr/bin/env bash
# Admin Web — Flutter 빌드 + rsync (Apache/SSL 미포함)
# 래퍼만 사용:
#   ./deploy/deploy-adminchat.sh   → 운영 adminchat.kr
#   ./deploy/deploy-admin-dev.sh   → QA admin-dev.adminchat.kr
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -z "${DEPLOY_CONFIG:-}" ]]; then
  echo "ERROR: deploy-admin.sh 직접 실행 금지. 래퍼를 사용하세요:"
  echo "  ./deploy/deploy-adminchat.sh   # 운영"
  echo "  ./deploy/deploy-admin-dev.sh   # QA"
  exit 1
fi
if [[ ! -f "$DEPLOY_CONFIG" ]]; then
  echo "ERROR: DEPLOY_CONFIG 없음: $DEPLOY_CONFIG"
  exit 1
fi

# shellcheck disable=SC1090
source "$DEPLOY_CONFIG"

REMOTE="${DEPLOY_SSH:?DEPLOY_SSH 필요}"
REMOTE_WEB_DIR="${REMOTE_WEB_DIR:?REMOTE_WEB_DIR 필요}"
ENV_BUILD="${ENV_BUILD_FILE:?ENV_BUILD_FILE 필요}"
DEPLOY_DOMAIN="${DEPLOY_DOMAIN:?DEPLOY_DOMAIN 필요}"

# QA·운영만 허용
case "$REMOTE_WEB_DIR:$DEPLOY_DOMAIN" in
  /home/users/adminchat/www:adminchat.kr) ;;
  /home/users/admin-dev/www:admin-dev.adminchat.kr) ;;
  *)
    echo "ERROR: 허용되지 않은 Web 경로/도메인: $REMOTE_WEB_DIR / $DEPLOY_DOMAIN"
    echo "  허용: 운영 /home/users/adminchat/www (adminchat.kr)"
    echo "       QA   /home/users/admin-dev/www (admin-dev.adminchat.kr)"
    exit 1
    ;;
esac

ENV_LOCAL_BAK=$(mktemp)
if [[ -f "$ROOT/.env" ]]; then
  cp "$ROOT/.env" "$ENV_LOCAL_BAK"
else
  ENV_LOCAL_BAK=""
fi
restore_local_env() {
  if [[ -n "$ENV_LOCAL_BAK" && -f "$ENV_LOCAL_BAK" ]]; then
    cp "$ENV_LOCAL_BAK" "$ROOT/.env"
    rm -f "$ENV_LOCAL_BAK"
  fi
}
trap restore_local_env EXIT

echo "==> 빌드용 .env 적용 ($ENV_BUILD)"
cp "$ENV_BUILD" "$ROOT/.env"

if [[ "${SKIP_WEB_BUILD:-0}" != "1" ]]; then
  echo "==> Flutter Web 빌드 (API: $(grep '^API_BASE_URL=' "$ENV_BUILD" | cut -d= -f2-))"
  cd "$ROOT"
  flutter pub get
  flutter build web --release

  echo "==> 서버 업로드 ($REMOTE:$REMOTE_WEB_DIR)"
  ssh "$REMOTE" "mkdir -p $REMOTE_WEB_DIR"
  rsync -avz --delete "$ROOT/build/web/" "$REMOTE:$REMOTE_WEB_DIR/"
else
  echo "==> SKIP_WEB_BUILD=1 — Flutter 빌드·Web 업로드 생략"
fi

echo "==> 로컬 .env 복원"

echo "==> 완료: https://$DEPLOY_DOMAIN"
echo ""
echo "배포 후 확인:"
echo "  curl -sI https://$DEPLOY_DOMAIN/ | head -1"
echo "  curl -s https://$DEPLOY_DOMAIN/api/health"
