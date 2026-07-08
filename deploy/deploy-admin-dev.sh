#!/usr/bin/env bash
# admin-dev.adminchat.kr — deploy-admin.sh + deploy.config.admin-dev
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEPLOY_CONFIG="$ROOT/deploy/deploy.config.admin-dev"
exec "$ROOT/deploy/deploy-admin.sh" "$@"
