FROM rclone/rclone

RUN apk add postgresql-client

COPY backup.sh /usr/local/bin/
