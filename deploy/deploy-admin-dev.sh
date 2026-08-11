#!/usr/bin/env bash
# QA — admin-dev.adminchat.kr Web (/home/users/admin-dev/www)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEPLOY_CONFIG="$ROOT/deploy/deploy.config.admin-dev"
exec "$ROOT/deploy/deploy-admin.sh" "$@"
