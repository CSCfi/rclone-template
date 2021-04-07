#!/bin/sh -e

if [ -z "${DBNAME}" ];
then
  echo "ERROR: DBNAME env variable is not defined"
  exit 1
fi

if [ -z "${DBHOST}" ];
then
  echo "ERROR: DBHOST env variable is not defined"
  exit 1
fi

if [ -z "${DBUSER}" ];
then
  echo "ERROR: DBUSER env variable is not defined"
  exit 1
fi

if [ -z "${BUCKET_DIR}" ];
then
  echo "ERROR: BUCKET_DIR env variable is not defined"
  exit 1
fi

if [ -z "${PGPASSWORD}" ];
then
  echo "ERROR: PGPASSWORD env variable is not defined"
  exit 1
fi

######
BACKUPFILE="/tmp/${DBHOST}-${DBNAME}-$(date +%Y%m%d-%H%M).SQL"
export BACKUPFILE

pg_dump "${DBNAME}" -U "${DBUSER}" -h "${DBHOST}" >"${BACKUPFILE}"

rclone copy "${BACKUPFILE}" "default:${BUCKET_DIR}"

echo "File ${BACKUPFILE} copied to default:${BUCKET_DIR}"
