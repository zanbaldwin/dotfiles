#!/usr/bin/env bash
set -euo pipefail

# Usage: update-map-tiles.sh nl|regions|world [--dry-run]
#
# TrueNAS cron jobs:
#   nl       weekly
#   regions  monthly
#   world    monthly

export TILES_DIRECTORY="/mnt/fast/apps/dawarich/tiles"
export PMTILES_IMAGE="protomaps/go-pmtiles:v1.31.2"

ARCHIVE="${1:-}"
DRY_RUN="${2:-}"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

EXTRACT_ARGS=()
case "${ARCHIVE}" in
    nl)
        EXTRACT_ARGS+=('--bbox=3.31,50.75,7.23,53.56')
        ;;
    regions)
        # England, then British Columbia.
        cat > "${TEMP_DIR}/regions.geojson" <<'EOF'
{
    "type": "MultiPolygon",
    "coordinates": [
        [[[-6.42, 49.86], [1.77, 49.86], [1.77, 55.81], [-6.42, 55.81], [-6.42, 49.86]]],
        [[[-139.06, 48.22], [-114.03, 48.22], [-114.03, 60.00], [-139.06, 60.00], [-139.06, 48.22]]]
    ]
}
EOF
        EXTRACT_ARGS+=('--region=/region.geojson')
        ;;
    world)
        EXTRACT_ARGS+=('--maxzoom=10')
        ;;
    *)
        echo >&2 "Usage: $(basename "$0") nl|regions|world [--dry-run]"
        exit 1
        ;;
esac

if [[ "${DRY_RUN}" == "--dry-run" ]]; then
    EXTRACT_ARGS+=('--dry-run')
fi

# Daily builds are kept for 7 days only.
BUILD_URL=""
for DAYS_AGO in 0 1 2 3 4 5 6; do
    CANDIDATE="https://build.protomaps.com/$(date -d "-${DAYS_AGO} days" +%Y%m%d).pmtiles"
    if curl -fsI "${CANDIDATE}" > /dev/null; then
        BUILD_URL="${CANDIDATE}"
        break
    fi
done
if [[ -z "${BUILD_URL}" ]]; then
    echo >&2 "ERROR: no Protomaps build found from the last 7 days"
    exit 1
fi

VOLUMES=(--volume "${TILES_DIRECTORY}:/data")
if [[ -f "${TEMP_DIR}/regions.geojson" ]]; then
    chmod 0644 "${TEMP_DIR}/regions.geojson"
    VOLUMES+=(--volume "${TEMP_DIR}/regions.geojson:/region.geojson:ro")
fi

# The ".tmp" suffix stops go-pmtiles serving the archive while it is written.
echo "Extracting \"${ARCHIVE}\" from \"${BUILD_URL}\"..."
docker run --rm --user 1000:1000 "${VOLUMES[@]}" "${PMTILES_IMAGE}" \
    extract "${BUILD_URL}" "/data/${ARCHIVE}.pmtiles.tmp" "${EXTRACT_ARGS[@]}"

if [[ "${DRY_RUN}" == "--dry-run" ]]; then
    exit 0
fi

mv "${TILES_DIRECTORY}/${ARCHIVE}.pmtiles.tmp" "${TILES_DIRECTORY}/${ARCHIVE}.pmtiles"
echo "Map tiles \"${ARCHIVE}\" updated."
