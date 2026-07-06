#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-/var/www}"
SITE_NAME="guthib.org"
AVAILABLE="/etc/nginx/sites-available/$SITE_NAME"
ENABLED="/etc/nginx/sites-enabled/$SITE_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_USER="${SUDO_USER:-$USER}"

if [[ ! -f "$REPO_ROOT/guthib/index.html" ]]; then
  echo "Error: $REPO_ROOT/guthib/index.html not found."
  exit 1
fi

echo "Removing broken nginx configs..."
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/guthib
sudo rm -f /etc/nginx/sites-available/guthib
sudo rm -f "$ENABLED" "$AVAILABLE"

echo "Installing nginx config..."
sudo cp "$SCRIPT_DIR/nginx/guthib.org.conf" "$AVAILABLE"
sudo ln -sf "$AVAILABLE" "$ENABLED"

echo "Setting up guestbook API..."
cd "$REPO_ROOT/guestbook-server"
npm ci --omit=dev
sudo sed "s/User=jialishi0713/User=$SERVICE_USER/" "$SCRIPT_DIR/guthib-guestbook.service" | sudo tee /etc/systemd/system/guthib-guestbook.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable guthib-guestbook
sudo systemctl restart guthib-guestbook

echo "Fixing permissions..."
sudo chmod o+x /var/www
sudo chmod -R a+rX "$REPO_ROOT/guthib"

echo "Testing nginx..."
sudo nginx -t
sudo systemctl reload nginx

echo "Done."
echo "Site:  https://guthib.org"
echo "Guestbook: https://guthib.org/guestbook.html"
