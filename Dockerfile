# Base image for your bot
FROM python:3.11-slim

# 1. Install tools + ntpsec (instead of deprecated ntp)
RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates git ffmpeg ntpsec tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Install latest Rclone
RUN curl -fsSLo /tmp/rclone.zip https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip /tmp/rclone.zip -d /tmp && \
    cp /tmp/rclone-*-linux-amd64/rclone /usr/bin/rclone && \
    chown root:root /usr/bin/rclone && \
    chmod 755 /usr/bin/rclone && \
    rm -rf /tmp/rclone*

# 3. Workdir + copy files
WORKDIR /app
COPY . /app

# Fix entrypoint permission
RUN chmod +x /app/entrypoint.sh

# Install Python deps
RUN pip install --no-cache-dir -r requirements.txt

# 4. Volumes & env
VOLUME ["/config", "/downloads"]
ENV RCLONE_CONFIG_PATH=/config/rclone.conf
ENV TEMP_DOWNLOAD_DIR=/downloads
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# 5. Entrypoint with TIME SYNC (using ntpsec)
ENTRYPOINT ["/bin/bash", "-c", \
    "echo 'Syncing time with ntpsec...' && \
     ntpd -n -q -p pool.ntp.org || echo 'NTP sync failed, continuing...' && \
     echo 'UTC Time: $(date -u)' && \
     /app/entrypoint.sh"]
