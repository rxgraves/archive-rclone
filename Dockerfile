# Base image
FROM python:3.11-slim

# Install required packages + openntpd for time sync
RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates git ffmpeg openntpd tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install latest Rclone
RUN curl -fsSLo /tmp/rclone.zip https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip /tmp/rclone.zip -d /tmp && \
    cp /tmp/rclone-*-linux-amd64/rclone /usr/bin/rclone && \
    chown root:root /usr/bin/rclone && \
    chmod 755 /usr/bin/rclone && \
    rm -rf /tmp/rclone*

# Set working directory
WORKDIR /app
COPY . /app

# Copy NTP config
COPY ntp.conf /etc/ntp.conf

# Fix entrypoint permission
RUN chmod +x /app/entrypoint.sh

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Volumes & environment
VOLUME ["/config", "/downloads"]
ENV RCLONE_CONFIG_PATH=/config/rclone.conf
ENV TEMP_DOWNLOAD_DIR=/downloads
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# Start NTP daemon + force sync + run bot
ENTRYPOINT ["/bin/bash", "-c", \
    "echo 'Starting OpenNTPD daemon...' && \
     ntpd -d -s -f /etc/ntp.conf & \
     sleep 3 && \
     echo 'Forcing time sync with ntpdate...' && \
     ntpdate -u pool.ntp.org || echo 'ntpdate failed, but ntpd is running' && \
     echo 'Current UTC time: $(date -u)' && \
     /app/entrypoint.sh"]
