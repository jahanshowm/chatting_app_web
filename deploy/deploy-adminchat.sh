#!/usr/bin/env bash
# 운영 — adminchat.kr Web (/home/users/adminchat/www)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEPLOY_CONFIG="$ROOT/deploy/deploy.config"
exec "$ROOT/deploy/deploy-admin.sh" "$@"
