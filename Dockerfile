# Base image
FROM python:3.11-slim

# Install curl + unzip + tzdata
RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates tzdata && \
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

# NO VOLUME HERE (Railway bans it)

ENV RCLONE_CONFIG_PATH=/config/rclone.conf
ENV TEMP_DOWNLOAD_DIR=/downloads
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# Force time sync via HTTP
ENTRYPOINT ["/bin/bash", "-c", \
    "echo 'Forcing time sync via HTTP...' && \
     TIME=$(curl -s --max-time 5 https://worldtimeapi.org/api/timezone/UTC.txt | grep 'datetime' | cut -d: -f2- | tr -d ' \"') && \
     if [ -n \"$TIME\" ]; then \
       echo \"Setting system time to: $TIME\" && \
       date -u -s \"$TIME\" > /dev/null; \
     else \
       echo 'HTTP time sync failed, using system time'; \
     fi && \
     echo 'FINAL TIME: $(date -u)' && \
     /app/entrypoint.sh"]
