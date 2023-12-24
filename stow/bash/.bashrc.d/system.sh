#!/bin/bash

# Better display of hard disk usage.
command -v "duf" >"/dev/null" 2>&1 && {
    alias df="duf";
} || {
    command -v "df" >"/dev/null" 2>&1 && {
        alias df="df -h | grep -v snap";
    };
}

command -v "xclip" >"/dev/null" 2>&1 && {
    alias copy="xclip -sel clip";
    alias paste="xclip -out -sel clip";
}

alias utc='date -u "+%Y%m%dT%H%M%SZ"'

function create_secure() {
    FOLDER=${1:-"/tmp/secure"}
    sudo mount -t ramfs -o size=1M ramfs "${FOLDER}"
    sudo chown "$(logname):$(logname)" "${FOLDER}"
}
function destroy_secure() {
    FOLDER=${1:-"/tmp/secure"}
    sudo umount "${FOLDER}"
}
