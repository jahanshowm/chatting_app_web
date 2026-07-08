#!/usr/bin/env bash
set -euo pipefail

# adminchat.kr — deploy-admin.sh + deploy.config.adminchat (Web rsync만)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEPLOY_CONFIG="$ROOT/deploy/deploy.config.adminchat"
exec "$ROOT/deploy/deploy-admin.sh" "$@"
