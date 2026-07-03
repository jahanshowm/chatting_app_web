#!/usr/bin/env bash
set -euo pipefail

# randomchat.kr Apache 설정만 동기화 (Flutter 빌드 없음)
# HTTP vhost + bitnami-le-ssl.conf + bitnami.conf 오타 수정

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${DEPLOY_CONFIG:-$ROOT/deploy/deploy.config.randomchat}"
export SKIP_WEB_BUILD=1
export DEPLOY_CONFIG="$CONFIG"
exec "$ROOT/deploy/deploy-admin.sh" "$@"
