#!/bin/bash

# uninstall.sh
# This script removes the main.py systemd service and its related cron job.

SERVICE_NAME="print-server"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Get the directory of this uninstall.sh
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPLOADS_PATH="$DIR/uploads"

echo "Stopping and disabling systemd service..."

sudo systemctl stop "$SERVICE_NAME"
sudo systemctl disable "$SERVICE_NAME"

echo "Removing systemd service file..."
sudo rm -f "$SERVICE_FILE"

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Removing cron job for deleting uploads contents..."

# Prepare grep-safe path
SAFE_UPLOADS_PATH=$(echo "$UPLOADS_PATH" | sed 's/\//\\\//g')

# Remove lines containing uploads path from crontab
( crontab -l 2>/dev/null | grep -v "$SAFE_UPLOADS_PATH" ) | crontab -

echo "Uninstall completed successfully."
