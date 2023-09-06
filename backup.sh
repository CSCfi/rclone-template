#!/bin/sh -e

# Help function
Help()
{
    echo "Backup database"
    echo
    echo "Usage: `basename ${0}` [ -D | --database ] [ -H | --host ] [ -U | -user ] [ -P | --password ] [ -B | --bucket ]"
    echo "options:"
    echo "-D | -d | ---database   Name of your database."
    echo "-H | -h | ---host       Name of the host where the database is located. Must be either 'postgresql' or 'mariadb'"
    echo "-U | -u | ---user       Name of the database user with enough access to dump the database."
    echo "-P | -p | ---password   Password of the user with enough access to dump the database."
    echo "-B | -b | ---bucket     Name of the S3 bucket where you want to dump your database."
}
while [[ $# -gt 0 ]];
do case $1 in
    -T | -t | --type) TYPE="$2"
        shift 2
        ;;
    -D | -d | --database) DBNAME="$2"
        shift 2
        ;;
    -H | -h | --host) DBHOST="$2"
        shift 2
        ;;
    -U | -u | --user) DBUSER="$2"
        shift 2
        ;;
    -B | -b | --bucket) BUCKET_DIR="$2"
        shift 2
        ;;
    -P | -p | --password) PGPASSWORD="$2"
        shift 2
        ;;
    --help)
        Help
        exit 0
        ;;
    *)
        echo "Option '$1' is unknown. Type --help to display help message"
        exit 1
        ;;
esac done

# Check if all args are here
if [ -z "$DBNAME" ]; then
  echo "ERROR: DBNAME env variable is not defined"
  echo "Type --help to display help message"
  exit 1
fi

if [ -z "$DBHOST" ]; then
  echo "ERROR: DBHOST env variable must be either 'postgresql' or 'mariadb'"
  echo "Type --help to display help message"
  exit 1
fi

if [ -z "$DBUSER" ]; then
  echo "ERROR: DBUSER env variable is not defined"
  echo "Type --help to display help message"
  exit 1
fi

if [ -z "$PGPASSWORD" ]; then
  echo "ERROR: DBPASSWORD env variable is not defined"
  echo "Type --help to display help message"
  exit 1
fi

if [ -z "$BUCKET_DIR" ]; then
  echo "ERROR: BUCKET_DIR env variable is not defined"
  echo "Type --help to display help message"
  exit 1
fi

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
