# Base image
FROM python:3.11-slim

# Install tools only (no NTP needed if host time is mounted)
RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates git ffmpeg tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Rclone
RUN curl -fsSLo /tmp/rclone.zip https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip /tmp/rclone.zip -d /tmp && \
    cp /tmp/rclone-*-linux-amd64/rclone /usr/bin/rclone && \
    chmod 755 /usr/bin/rclone && \
    rm -rf /tmp/rclone*

WORKDIR /app
COPY . /app
RUN chmod +x /app/entrypoint.sh
RUN pip install --no-cache-dir -r requirements.txt

VOLUME ["/config", "/downloads"]
ENV RCLONE_CONFIG_PATH=/config/rclone.conf
ENV TEMP_DOWNLOAD_DIR=/downloads
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# Simple entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
