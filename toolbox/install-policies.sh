#!/bin/bash

if [ -f "/run/.containerenv" ]; then
    echo >&2 "Must be run on root filesystem, outside of container.";
    exit 1;
fi

if ! command -v "jq" >"/dev/null" 2>&1; then
    echo >&2 "Could not find jq tool on \$PATH.";
    exit 1;
fi

if [ "$(id -u)" != "0" ]; then
    echo >&2 "Must run this script as root.";
    exit 1;
fi

# Force Chromium to always allow Unsecured HTTP for Localhost, without force
# redirecting to HTTPS. Add the string "localhost" to the HSTSPolicyBypassList
# array inside already existing JSON, defaulting to an empty object when the
# file does not exist or is invalid JSON.
TEMPFILE="$(mktemp)" # (to prevent race conditions inside pipelines)
mkdir -p "/etc/opt/chrome/policies/managed"
(cat "/etc/opt/chrome/policies/managed/policies.json" 2>/dev/null || echo '{}') \
    | (grep "." || echo '{}') \
    | (jq 2>/dev/null || echo '{}') \
    | jq '.HSTSPolicyBypassList|=(.+["localhost"]|unique)' >"${TEMPFILE}" \
    && mv "${TEMPFILE}" "/etc/opt/chrome/policies/managed/policies.json"

chmod 0644 "/etc/opt/chrome/policies/managed/policies.json"
