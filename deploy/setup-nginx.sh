#!/usr/bin/env bash
set -euo pipefail

SITE_NAME="guthib.org"
AVAILABLE="/etc/nginx/sites-available/$SITE_NAME"
ENABLED="/etc/nginx/sites-enabled/$SITE_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f /var/www/guthib/index.html ]]; then
  echo "Error: /var/www/guthib/index.html not found."
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

echo "Fixing permissions..."
sudo chmod o+x /var/www
sudo chmod -R a+rX /var/www/guthib

echo "Testing nginx..."
sudo nginx -t
sudo systemctl reload nginx

echo "Done. Site should be live at https://guthib.org"
