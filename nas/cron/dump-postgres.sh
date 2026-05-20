#!/usr/bin/env bash
set -euo pipefail

export BACKUP_DIRECTORY="/mnt/tank4/backups/postgres"
mkdir -p "${BACKUP_DIRECTORY}"

TEMP_EXPORT_DIR="$(mktemp -d)"
export TEMP_EXPORT_DIR
echo "Using temp directory \"${TEMP_EXPORT_DIR}\"..."
trap 'rm -rf "${TEMP_EXPORT_DIR}"' EXIT

export APP_NAME="data"
export SERVICE_NAME="postgres"
export CONTAINER_NAME="ix-${APP_NAME}-${SERVICE_NAME}-1"

pgexec() {
    docker exec "${CONTAINER_NAME}" psql \
        --username='main' --tuples-only --no-align \
        --no-psqlrc --set='ON_ERROR_STOP=on' \
        "$@"
}

pgdumpone() {
    docker exec "${CONTAINER_NAME}" pg_dump \
        --username='main' --clean \
        --inserts --column-inserts \
        --quote-all-identifiers \
        --disable-dollar-quoting \
        --if-exists --statistics \
        "$@"
}

pgdumpall() {
    docker exec "${CONTAINER_NAME}" pg_dumpall \
        --username='main' --clean \
        --inserts --column-inserts \
        --quote-all-identifiers \
        --disable-dollar-quoting \
        --if-exists --statistics \
        --sequence-data \
        "$@"
}

LIST_DATABASES_SQL='SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true ORDER BY datname;'
DATABASE_LIST="$(pgexec --command="${LIST_DATABASES_SQL}")"
mapfile -t DATABASES <<<"${DATABASE_LIST}"

# The database list is always appended by a newline. So if the list is empty,
# mapfile may interpret it as a list containing a single empty string, instead
# of an array of zero.
if [[ ${#DATABASES[@]} -eq 0 || -z "${DATABASES[0]}" ]]; then
    echo >&2 "ERROR: no databases enumerated from ${CONTAINER_NAME}"
    exit 1
fi

for DB in "${DATABASES[@]}"; do
    echo >&2 "Dumping database \"${DB}\"..."
    pgdumpone --dbname="${DB}" > "${TEMP_EXPORT_DIR}/${DB}.sql"
done

echo >&2 "Dumping globals..."
pgdumpall --globals-only > "${TEMP_EXPORT_DIR}/globals.sql"

echo "Moving dumps to backup directory \"${BACKUP_DIRECTORY}\"..."
mv "${TEMP_EXPORT_DIR}"/*.sql "${BACKUP_DIRECTORY}/"
echo "Postgres databases dumped to SQL files."
