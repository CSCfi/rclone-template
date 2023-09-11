#!/bin/sh -e

# If using uppercase letters, reassign into TYPELOWER with only lowercase. Then, check if it's postgres, mariadb
TYPELOWER=$(echo "$DBHOST" | tr '[:upper:]' '[:lower:]')

if [ "$TYPELOWER" == "postgresql" ]; then
    BACKUPFILE="/tmp/${DBHOST}-${DBNAME}-$(date +%Y%m%d-%H%M).SQL"
    export BACKUPFILE

    pg_dump -h ${DBHOST} -p 5432 --format=custom --file ${BACKUPFILE} -U ${DBUSER} ${DBNAME}
    rclone copy "${BACKUPFILE}" "default:${BUCKET_DIR}"
    echo "File ${BACKUPFILE} copied to default:${BUCKET_DIR}"

    exit 0
fi

if [ "$TYPELOWER" == "mariadb" ]; then
    BACKUPFILE="/tmp/${DBHOST}-${DBNAME}-$(date +%Y%m%d-%H%M).SQL"
    export BACKUPFILE
    
    mariadb-dump -h "${DBHOST}" -u "${DBUSER}" --port 3306 -p"${PGPASSWORD}" --databases "${DBNAME}" > "${BACKUPFILE}"
    if [ "$?" == "0" ]
    then
      rclone copy "${BACKUPFILE}" "default:${BUCKET_DIR}"
      echo "File ${BACKUPFILE} from ${DBHOST} copied to default:${BUCKET_DIR}. Using mariadb-dump command"
    else
      echo "Failed with mariadb-dump, let's try with mysqldump"
      mysqldump -h "${DBHOST}" -u "${DBUSER}" --port 3306 -p"${PGPASSWORD}" --databases "${DBNAME}" > "${BACKUPFILE}"
      rclone copy "${BACKUPFILE}" "default:${BUCKET_DIR}"
      echo "File ${BACKUPFILE} from ${DBHOST} copied to default:${BUCKET_DIR}. Using mysqldump command"
    fi

    exit 0
fi
