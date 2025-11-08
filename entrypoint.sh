#!/bin/bash
set -e

# Ensure directories exist
mkdir -p /config /downloads

# Show current time (debug)
echo "Container started at: $(date -u)"

# Check rclone config
if [ ! -f "$RCLONE_CONFIG_PATH" ]; then
  echo "No rclone config found at $RCLONE_CONFIG_PATH. Upload via bot or mount one."
fi

# Start bot
echo "Starting bot..."
exec python /app/bot.py
