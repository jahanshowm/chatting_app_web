#!/usr/bin/env bash
set -euo pipefail

# Admin CMS 전체 배포: Backend(API) → Admin Web
# 사용: ./deploy/deploy-all.sh [user@13.209.176.251]

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_ROOT="$(cd "$ROOT/../randomchat_back" && pwd)"
REMOTE="${1:-}"

echo "========================================"
echo " Admin CMS 전체 배포 (adminchat.kr)"
echo "========================================"

echo ""
echo "[1/2] Backend + migration"
"$BACKEND_ROOT/deploy/deploy-backend.sh" ${REMOTE:+"$REMOTE"}

echo ""
echo "[2/2] Admin Web"
"$ROOT/deploy/deploy-admin.sh" ${REMOTE:+"$REMOTE"}

echo ""
echo "========================================"
echo " 배포 완료: https://adminchat.kr"
echo "========================================"
