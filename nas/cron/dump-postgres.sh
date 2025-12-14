#!/bin/bash
set -ex

export BACKUP_DIRECTORY="/mnt/tank4/backups/postgres"
export BACKUP_FILENAME="databases.sql"

export APP_NAME="data"
export SERVICE_NAME="postgres"
export CONTAINER_NAME="ix-${APP_NAME}-${SERVICE_NAME}-1"

mkdir -p "${BACKUP_DIRECTORY}" >'/dev/null' || true;
docker exec "${CONTAINER_NAME}" pg_dumpall \
    --clean \
    --column-inserts \
    --disable-dollar-quoting \
    --if-exists \
    --inserts \
    --quote-all-identifiers \
    --sequence-data \
    --statistics \
    --username='main' \
    >"${BACKUP_DIRECTORY}/${BACKUP_FILENAME}";
echo "Postgres dumped to SQL file."
