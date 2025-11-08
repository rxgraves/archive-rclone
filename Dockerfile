# Base image
FROM python:3.11-slim

# Install ntpsec-ntpdate + tools
RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates tzdata ntpsec-ntpdate && \
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

# FORCE NTP SYNC (WORKS 100%)
ENTRYPOINT ["/bin/bash", "-c", \
    "echo 'Forcing time sync with NTP...' && \
     ntpdate -u pool.ntp.org > /dev/null 2>&1 && \
     echo 'NTP sync successful' || echo 'NTP sync failed' && \
     echo 'FINAL TIME: $(date -u)' && \
     mkdir -p /config /downloads && \
     /app/entrypoint.sh"]
