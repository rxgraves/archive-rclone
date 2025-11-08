#!/bin/bash
set -e

mkdir -p /config /downloads

echo "Container started at: $(date -u)"

if [ ! -f "$RCLONE_CONFIG_PATH" ]; then
  echo "No rclone config found at $RCLONE_CONFIG_PATH. Upload via bot or mount one."
fi

# Optional: Force sync again (if needed)
# ntpd -n -q -p pool.ntp.org

echo "Starting bot..."
exec python /app/bot.py
