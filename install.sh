#!/bin/bash

# install.sh
# This script installs main.py as a systemd service and sets a cron job
# to delete all contents in the uploads directory of this folder.

# Get the directory of this install.sh
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$DIR/main.py"
UPLOADS_PATH="$DIR/uploads"

# Check if main.py exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: $SCRIPT_PATH does not exist."
    exit 1
fi

# Create uploads directory if it doesn't exist
mkdir -p "$UPLOADS_PATH"

PYTHON_PATH=$(which python3)
SERVICE_NAME="print-server"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "Creating systemd service file at $SERVICE_FILE..."

cat << EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Python $SERVICE_NAME
After=network.target

[Service]
Type=simple
ExecStart=$PYTHON_PATH $SCRIPT_PATH
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Enabling and starting $SERVICE_NAME..."
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

echo "Setting up cron job to delete uploads contents..."

# Prepare the cron line (this example deletes every day at 3 AM)
# CRON_JOB="0 3 * * * /usr/bin/find $UPLOADS_PATH -mindepth 1 -delete"

# (Alternative: delete on every reboot)
CRON_JOB="@reboot /usr/bin/find $UPLOADS_PATH -mindepth 1 -delete"

# Add cron job if it does not already exist
( crontab -l 2>/dev/null | grep -v -F "$UPLOADS_PATH" ; echo "$CRON_JOB" ) | crontab -

echo "Cron job added. It will delete all contents inside $UPLOADS_PATH as scheduled."

echo "Installation completed successfully."
