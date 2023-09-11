FROM rclone/rclone

RUN apk add postgresql-client
RUN apk add mariadb-client

COPY backup.sh /usr/local/bin/