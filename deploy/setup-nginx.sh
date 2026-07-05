#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-}"
if [[ -z "$REPO_ROOT" ]]; then
  echo "Usage: $0 /path/to/guthib-repo"
  echo "Example: $0 /home/ubuntu/guthib"
  exit 1
fi

if [[ ! -d "$REPO_ROOT/www/guthib" ]]; then
  echo "Error: $REPO_ROOT/www/guthib not found."
  echo "Run this from the directory where git pull updates your site."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_NAME="guthib.org"
AVAILABLE="/etc/nginx/sites-available/$SITE_NAME"
ENABLED="/etc/nginx/sites-enabled/$SITE_NAME"

echo "Removing old nginx site config for $SITE_NAME (if any)..."
sudo rm -f "$ENABLED" "$AVAILABLE"

echo "Installing fresh nginx config..."
sudo sed "s|__REPO_ROOT__|$REPO_ROOT|g" "$SCRIPT_DIR/nginx/guthib.org.conf" | sudo tee "$AVAILABLE" > /dev/null
sudo ln -sf "$AVAILABLE" "$ENABLED"

echo "Testing nginx configuration..."
sudo nginx -t

echo "Reloading nginx..."
sudo systemctl reload nginx

echo "Done. nginx now serves from $REPO_ROOT/www/guthib"
