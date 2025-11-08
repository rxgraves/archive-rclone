# Base image
FROM python:3.11-slim

# Install curl + unzip + tzdata + sudo
RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates tzdata sudo && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo "ALL ALL=(ALL) NOPASSWD: /bin/date" >> /etc/sudoers && \
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

# NO VOLUME (Railway bans it)
ENV RCLONE_CONFIG_PATH=/config/rclone.conf
ENV TEMP_DOWNLOAD_DIR=/downloads
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# FINAL TIME SYNC (root user)
ENTRYPOINT ["/bin/bash", "-c", \
    "echo 'Forcing time sync via HTTP...' && \
     TIME=$(curl -s --max-time 10 https://worldtimeapi.org/api/timezone/UTC.json | grep -oP '(?<=\"datetime\":\")[^\"]+' | head -1) && \
     if [ -n \"$TIME\" ]; then \
       CLEAN_TIME=$(echo \"$TIME\" | cut -d'.' -f1 | tr 'T' ' ') && \
       echo \"Setting system time to: $CLEAN_TIME\" && \
       date -u -s \"$CLEAN_TIME\" > /dev/null 2>&1 && \
       echo 'Time sync successful'; \
     else \
       echo 'HTTP time sync failed, using system time'; \
     fi && \
     echo 'FINAL TIME: $(date -u)' && \
     mkdir -p /config /downloads && \
     /app/entrypoint.sh"]
