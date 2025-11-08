# Base image
FROM python:3.11-slim

# Install curl + tools
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

ENV RCLONE_CONFIG_PATH=/config/rclone.conf
ENV TEMP_DOWNLOAD_DIR=/downloads
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# FINAL RELIABLE HTTP SYNC (Railway allows HTTP)
ENTRYPOINT ["/bin/bash", "-c", \
    "echo 'Forcing time sync via HTTP...' && \
     for i in {1..5}; do \
       TIME=$(curl -s --max-time 10 'http://worldtimeapi.org/api/timezone/UTC.txt' | grep '^datetime:' | cut -d' ' -f2) && \
       if [ -n \"$TIME\" ]; then \
         CLEAN_TIME=$(echo \"$TIME\" | cut -d'.' -f1 | tr 'T' ' ') && \
         echo \"Setting system time to: $CLEAN_TIME\" && \
         date -u -s \"$CLEAN_TIME\" > /dev/null 2>&1 && \
         echo 'HTTP sync successful'; \
         break; \
       fi; \
       echo 'Attempt $i failed, retrying...'; \
       sleep 1; \
     done; \
     if ! date -u | grep -q UTC; then \
       echo 'All attempts failed, using system time'; \
     fi && \
     echo 'FINAL TIME: $(date -u)' && \
     mkdir -p /config /downloads && \
     /app/entrypoint.sh"]
