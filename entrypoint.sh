#!/bin/bash
set -e

# Create required directories
mkdir -p /config /downloads

# Check rclone config
if [ ! -f "$RCLONE_CONFIG_PATH" ]; then
  echo "No rclone config found at $RCLONE_CONFIG_PATH. Upload via bot or mount one."
fi

# Final time check before starting bot
echo "Final system time check: $(date -u)"
echo "Starting Archive Rclone Bot..."

# Run the bot
exec python /app/bot.py
