#!/usr/bin/env bash

# For some reason, if I shutdown the computer without exiting PHPStorm first, it
# leaves behind a lock file that prevents it from being opened the next time I
# turn on the computer. It's very annoying.
find "${HOME}/.var/app/com.jetbrains.PhpStorm/config" -type f -name '.lock' -exec rm --force --verbose '{}' \;
