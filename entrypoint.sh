#!/bin/bash
set -e

mkdir -p /config /downloads

if [ ! -f "$RCLONE_CONFIG_PATH" ]; then
  echo "No rclone config found. Upload via bot or mount one."
fi

echo "System time (from host): $(date -u)"
echo "Starting bot..."
exec python /app/bot.py
