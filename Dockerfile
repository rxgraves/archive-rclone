# Base image for your bot
FROM python:3.11-slim

# 1. Update and install necessary tools
# - curl, unzip: for rclone
# - ffmpeg, git: for bot functionality
# - ca-certificates: for HTTPS
# - ntp: for time synchronization (CRUCIAL for Pyrogram)
# - tzdata: for proper timezone handling
RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates git ffmpeg ntp tzdata && \
    # Set timezone to UTC (recommended for Telegram bots)
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Install the LATEST Rclone (with Linkbox support)
RUN curl -fsSLo /tmp/rclone.zip https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip /tmp/rclone.zip -d /tmp && \
    cp /tmp/rclone-*-linux-amd64/rclone /usr/bin/rclone && \
    chown root:root /usr/bin/rclone && \
    chmod 755 /usr/bin/rclone && \
    rm -rf /tmp/rclone*

# 3. Set working directory
WORKDIR /app
COPY . /app

# Fix entrypoint permission
RUN chmod +x /app/entrypoint.sh

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# 4. Define volumes and environment variables
VOLUME ["/config", "/downloads"]

ENV RCLONE_CONFIG_PATH=/config/rclone.conf
ENV TEMP_DOWNLOAD_DIR=/downloads
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# 5. Entrypoint with automatic time sync
ENTRYPOINT ["/bin/bash", "-c", \
    "echo 'Syncing system time with NTP...' && \
     ntpdate -u pool.ntp.org || echo 'NTP sync failed, continuing...' && \
     echo 'Current UTC time:' && date -u && \
     /app/entrypoint.sh"]
