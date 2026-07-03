#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${DEPLOY_CONFIG:-$ROOT/deploy/deploy.config}"

if [[ -f "$CONFIG" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG"
fi

REMOTE="${1:-${DEPLOY_SSH:-ubuntu@13.209.176.251}}"
REMOTE_WEB_DIR="${REMOTE_WEB_DIR:-/var/www/adminchat}"
ENV_PRODUCTION="${ENV_PRODUCTION_FILE:-$ROOT/.env.production}"
NGINX_SITE="${NGINX_CONF:-$ROOT/deploy/nginx/adminchat.kr.conf}"
NGINX_SITE_NAME="${NGINX_SITE_NAME:-${DEPLOY_DOMAIN:-adminchat.kr}}"
APACHE_SITE="${APACHE_CONF:-}"
APACHE_VHOST="${APACHE_VHOST_PATH:-/opt/bitnami/apache/conf/vhosts/${DEPLOY_DOMAIN:-randomchat.kr}-vhost.conf}"
APACHE_SSL_VHOST="${APACHE_SSL_VHOST_PATH:-/opt/bitnami/apache/conf/vhosts/${DEPLOY_DOMAIN:-randomchat.kr}-ssl-vhost.conf}"
WEB_SERVER="${DEPLOY_WEB_SERVER:-nginx}"

echo "==> 프로덕션 .env 적용 ($ENV_PRODUCTION)"
cp "$ENV_PRODUCTION" "$ROOT/.env"

echo "==> Flutter Web 빌드 (API: ${API_BASE_URL:-https://adminchat.kr})"
cd "$ROOT"
flutter pub get
flutter build web --release

echo "==> 서버 업로드 ($REMOTE:$REMOTE_WEB_DIR)"
ssh "$REMOTE" "sudo mkdir -p $REMOTE_WEB_DIR && sudo chown -R \$(whoami):\$(whoami) $REMOTE_WEB_DIR"
rsync -avz --delete "$ROOT/build/web/" "$REMOTE:$REMOTE_WEB_DIR/"

if [[ "$WEB_SERVER" == "apache" && -n "$APACHE_SITE" && -f "$APACHE_SITE" ]]; then
  echo "==> Apache vhost 설정 ($APACHE_VHOST)"
  scp "$APACHE_SITE" "$REMOTE:/tmp/randomchat-vhost.conf"
  SSL_LOCAL="${APACHE_SSL_CONF:-$ROOT/deploy/apache/randomchat.kr-ssl.conf}"
  if [[ -f "$SSL_LOCAL" ]]; then
    scp "$SSL_LOCAL" "$REMOTE:/tmp/randomchat-ssl-vhost.conf"
  fi
  ssh "$REMOTE" 'set -e
    HTTPD=/opt/bitnami/apache/conf/httpd.conf
    for pair in "proxy_module mod_proxy.so" "proxy_http_module mod_proxy_http.so"; do
      mod=${pair%% *}; file=${pair##* }
      if ! grep -rq "LoadModule ${mod}" /opt/bitnami/apache/conf/; then
        echo "LoadModule ${mod} modules/${file}" >> /opt/bitnami/apache/conf/bitnami/randomchat-proxy.conf
      fi
    done
    grep -q randomchat-proxy.conf "$HTTPD" 2>/dev/null || \
      echo "Include \"/opt/bitnami/apache/conf/bitnami/randomchat-proxy.conf\"" >> "$HTTPD"
    cp /tmp/randomchat-vhost.conf '"$APACHE_VHOST"'
    if [[ -f /tmp/randomchat-ssl-vhost.conf ]]; then
      cp /tmp/randomchat-ssl-vhost.conf '"$APACHE_SSL_VHOST"'
    fi
    /opt/bitnami/apache/bin/apachectl configtest
    MASTER=$(pgrep -f "/opt/bitnami/apache/bin/httpd" | head -1)
    if [[ -n "$MASTER" ]]; then
      kill -USR1 "$MASTER"
      echo "Apache graceful reload (pid=$MASTER)"
    else
      /opt/bitnami/ctlscript.sh start apache
    fi
  '
else
  echo "==> nginx 설정 ($NGINX_SITE_NAME)"
  scp "$NGINX_SITE" "$REMOTE:/tmp/${NGINX_SITE_NAME}.conf"
  ssh "$REMOTE" "sudo cp /tmp/${NGINX_SITE_NAME}.conf /etc/nginx/sites-available/${NGINX_SITE_NAME} && \
    sudo ln -sf /etc/nginx/sites-available/${NGINX_SITE_NAME} /etc/nginx/sites-enabled/${NGINX_SITE_NAME} && \
    sudo nginx -t && sudo systemctl reload nginx"
fi

echo "==> 로컬 .env 복원 (development)"
cp "$ROOT/.env.development" "$ROOT/.env" 2>/dev/null || true

echo "==> 완료: https://${DEPLOY_DOMAIN:-adminchat.kr}"
