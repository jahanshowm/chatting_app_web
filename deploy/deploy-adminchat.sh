#!/usr/bin/env bash
set -euo pipefail

# adminchat.kr Apache + Web (빌드·업로드 포함)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEPLOY_CONFIG="$ROOT/deploy/deploy.config.adminchat"
exec "$ROOT/deploy/deploy-admin.sh" "$@"
