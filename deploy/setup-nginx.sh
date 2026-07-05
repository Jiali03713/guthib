#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-}"
WEB_ROOT="/var/www/guthib"
SITE_NAME="guthib.org"
AVAILABLE="/etc/nginx/sites-available/$SITE_NAME"
ENABLED="/etc/nginx/sites-enabled/$SITE_NAME"

if [[ -z "$REPO_ROOT" ]]; then
  echo "Usage: $0 /path/to/guthib-repo"
  echo "Example: $0 /home/ubuntu/guthib"
  exit 1
fi

if [[ ! -f "$REPO_ROOT/www/guthib/index.html" ]]; then
  echo "Error: $REPO_ROOT/www/guthib/index.html not found."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Publishing site files to $WEB_ROOT..."
sudo mkdir -p "$WEB_ROOT"
sudo cp -a "$REPO_ROOT/www/guthib/." "$WEB_ROOT/"
sudo chown -R www-data:www-data "$WEB_ROOT"
sudo chmod -R a+rX "$WEB_ROOT"

echo "Installing nginx site config..."
sudo rm -f "$ENABLED" "$AVAILABLE"
sudo cp "$SCRIPT_DIR/nginx/guthib.org.conf" "$AVAILABLE"
sudo ln -sf "$AVAILABLE" "$ENABLED"

echo "Testing nginx configuration..."
sudo nginx -t

echo "Reloading nginx..."
sudo systemctl reload nginx

echo "Done. nginx serves from $WEB_ROOT"
