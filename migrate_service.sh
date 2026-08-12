#!/bin/bash

# --- Configuration ---
OLD_SERVICE="energy-monitor"
NEW_SERVICE="pm"
PROJECT_ROOT=$(pwd)  # Assumes you are running the script from the project root
LOG_DIR="/var/log/pm"
MONITOR_LOG="$LOG_DIR/monitor.log"

# Paths to update within the service file (Absolute paths required for systemd)
NEW_SCRIPT_PATH="$PROJECT_ROOT/lib/daemon.sh"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)."
   exit 1
fi

echo "Starting migration from ${OLD_SERVICE}.service to ${NEW_SERVICE}.service..."

# 1. Stop and Disable the old service
if systemctl is-active --quiet "$OLD_SERVICE"; then
    echo "Stopping $OLD_SERVICE..."
    systemctl stop "$OLD_SERVICE"
fi

echo "Disabling $OLD_SERVICE..."
systemctl disable "$OLD_SERVICE" 2>/dev/null || true

# 2. Rename the service file in systemd directory
SYSTEMD_PATH="/etc/systemd/system/$OLD_SERVICE.service"
NEW_SYSTEMD_PATH="/etc/systemd/system/$NEW_SERVICE.service"

if [ -f "$SYSTEMD_PATH" ]; then
    echo "Renaming service file to $NEW_SERVICE.service..."
    mv "$SYSTEMD_PATH" "$NEW_SYSTEMD_PATH"
elif [ -f "./etc/$NEW_SERVICE.service" ]; then 
    # Handle case if files are being moved within the repo context as mentioned in MD
    echo "Moving service file from project etc folder to systemd..."
    mv "./etc/$OLD_SERVICE.service" "$SYSTEMD_PATH" # Assuming old one was here based on prompt
fi

if [ ! -f "$NEW_SYSTEMD_PATH" ]; then
    echo "Error: Service file $NEW_SYSTEMD_PATH not found! Migration aborted."
    exit 1
fi

# 3. Update the service file content using sed
# We replace any existing ExecStart path with our new daemon script 
# and update potential log redirections to /var/log/pm/monitor.log
echo "Updating paths inside $NEW_SYSTEMD_PATH..."

# Note: This regex is flexible; it looks for the line containing 'ExecStart' 
# or redirection symbols '> /' and updates them.
sed -i "s|ExecStart=.*|ExecStart=$NEW_SCRIPT_PATH|g" "$NEW_SYSTEMD_PATH"
sed -i "s|/[^ ]*log/[^ ]*.log|$MONITOR_LOG|g" "$NEW_SYSTEMD_PATH" # Updates generic log paths to the new one

# 4. Setup Log Directory and Permissions
echo "Setting up log directory $LOG_DIR..."
mkdir -p "$LOG_DIR"
touch "$MONITOR_LOG"
chown -R root:root "$LOG_DIR"
chmod 755 "$LOG_DIR"
chown $(stat -c '%u:%g' /etc/systemd/system/) "$NEW_SYSTEMD_PATH"

# 5. Reload Systemd and Start New Service
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling $NEW_SERVICE service..."
systemctl enable "$NEW_SERVICE"

echo "Starting $NEW_SERVICE service..."
if systemctl start "$NEW_SERVICE"; then
    echo "--------------------------------------------------"
    echo "SUCCESS: Migration complete!"
    echo "New Service Name: $NEW_SERVICE"
    echo "Log File Location: $MONITOR_LOG"
    echo "Active Status:"
    systemctl status "$NEW_SERVICE" --no-pager | grep "Active:"
else
    echo "--------------------------------------------------"
    echo "ERROR: Failed to start the new service."
    echo "Check logs using: journalctl -u $NEW_SERVICE -n 20"
    exit 1
fi
