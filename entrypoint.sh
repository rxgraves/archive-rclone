#!/bin/bash
set -e

if [ ! -f "$RCLONE_CONFIG_PATH" ]; then
  echo "No rclone config found. Upload via bot or mount one."
fi

echo "Bot starting at: $(date -u)"
exec python /app/bot.py
