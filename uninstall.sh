#!/bin/sh

# uninstall.sh
# Removes main.py service and its deletion jobs
# Compatible with systemd and procd systems

SERVICE_NAME="print-server"

# Get directory of this uninstall.sh
DIR="$(cd "$(dirname "$0")" && pwd)"
UPLOADS_PATH="$DIR/uploads"

# Detect init system
if pidof systemd >/dev/null 2>&1; then
    INIT_SYSTEM="systemd"
elif [ -d /etc/init.d ] && grep -q procd /sbin/init 2>/dev/null; then
    INIT_SYSTEM="procd"
else
    INIT_SYSTEM="unknown"
fi

echo "Detected init system: $INIT_SYSTEM"

if [ "$INIT_SYSTEM" = "systemd" ]; then
    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

    echo "Stopping and disabling systemd service..."
    systemctl stop "$SERVICE_NAME"
    systemctl disable "$SERVICE_NAME"

    echo "Removing systemd service file..."
    rm -f "$SERVICE_FILE"

    echo "Reloading systemd daemon..."
    systemctl daemon-reload

elif [ "$INIT_SYSTEM" = "procd" ]; then
    SERVICE_FILE="/etc/init.d/${SERVICE_NAME}"

    echo "Stopping and disabling procd service..."
    /etc/init.d/$SERVICE_NAME stop
    /etc/init.d/$SERVICE_NAME disable

    echo "Removing procd service file..."
    rm -f "$SERVICE_FILE"

else
    echo "Unknown init system. Please remove service manually if it exists."
fi

# Remove cron job for deleting uploads contents
echo "Removing deletion job..."

if command -v crontab >/dev/null 2>&1; then
    # Prepare grep-safe path
    SAFE_UPLOADS_PATH=$(echo "$UPLOADS_PATH" | sed 's/\//\\\//g')

    # Remove lines containing uploads path from crontab
    ( crontab -l 2>/dev/null | grep -v "$SAFE_UPLOADS_PATH" ) | crontab -
    echo "Removed cron job entry."
fi

# Remove deletion line from /etc/rc.local if present
if [ -f /etc/rc.local ]; then
    if grep -q "$UPLOADS_PATH" /etc/rc.local; then
        sed -i "\|$UPLOADS_PATH|d" /etc/rc.local
        echo "Removed deletion command from /etc/rc.local."
    fi
fi

echo "Uninstall completed successfully."
