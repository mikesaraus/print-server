#!/bin/sh

# install.sh
# Installs main.py as a system service and sets a deletion job for uploads directory
# Auto-detects init system (systemd or procd) for compatibility

# Get directory of this script
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$DIR/main.py"
UPLOADS_PATH="$DIR/uploads"

# Check if main.py exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: $SCRIPT_PATH does not exist."
    exit 1
fi

# Create uploads directory if it doesn't exist
mkdir -p "$UPLOADS_PATH"

# Find python3 path
PYTHON_PATH=$(which python3)
if [ -z "$PYTHON_PATH" ]; then
    echo "python3 not found. Please install it first."
    exit 1
fi

# Detect init system
if pidof systemd >/dev/null 2>&1; then
    INIT_SYSTEM="systemd"
elif [ -d /etc/init.d ] && grep -q procd /sbin/init 2>/dev/null; then
    INIT_SYSTEM="procd"
else
    INIT_SYSTEM="unknown"
fi

echo "Detected init system: $INIT_SYSTEM"

SERVICE_NAME="print-server"

if [ "$INIT_SYSTEM" = "systemd" ]; then
    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

    echo "Creating systemd service at $SERVICE_FILE..."

    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Python $SERVICE_NAME
After=network.target

[Service]
Type=simple
WorkingDirectory=$DIR
ExecStart=$PYTHON_PATH $SCRIPT_PATH
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    echo "Reloading systemd..."
    systemctl daemon-reload

    echo "Enabling and starting $SERVICE_NAME..."
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"

elif [ "$INIT_SYSTEM" = "procd" ]; then
    SERVICE_FILE="/etc/init.d/${SERVICE_NAME}"

    echo "Creating procd service at $SERVICE_FILE..."

    cat << EOF > "$SERVICE_FILE"
#!/bin/sh /etc/rc.common
# PROCD init script for $SERVICE_NAME

START=99
STOP=10

USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param cwd $DIR
    procd_set_param command $PYTHON_PATH $SCRIPT_PATH
    procd_set_param respawn
    procd_close_instance
}
EOF

    chmod +x "$SERVICE_FILE"

    echo "Enabling and starting $SERVICE_NAME..."
    /etc/init.d/$SERVICE_NAME enable
    /etc/init.d/$SERVICE_NAME start

else
    echo "Unknown init system. Please create a manual startup script."
    exit 1
fi

# Set up deletion cronjob
echo "Setting up deletion of uploads cronjob..."

if command -v crontab >/dev/null 2>&1; then
    # Prepare the cron line (this example deletes every day at 3 AM)
    CRON_JOB="0 3 * * * /usr/bin/find $UPLOADS_PATH -mindepth 1 -delete"
    # CRON_JOB="@reboot /usr/bin/find $UPLOADS_PATH -mindepth 1 -delete"
    ( crontab -l 2>/dev/null | grep -v -F "$UPLOADS_PATH" ; echo "$CRON_JOB" ) | crontab -
    echo "Cron job added for deletion on reboot."
elif [ -f /etc/rc.local ]; then
    if ! grep -q "$UPLOADS_PATH" /etc/rc.local; then
        sed -i "/^exit 0/i /usr/bin/find $UPLOADS_PATH -mindepth 1 -delete" /etc/rc.local
        echo "Deletion command added to /etc/rc.local."
    fi
else
    echo "Neither cron nor /etc/rc.local available. Please set up deletion manually."
fi

echo "Installation completed successfully."
