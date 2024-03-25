#!/bin/bash

command -v nano >/dev/null 2>&1 && {
    # Already know that nano is on the PATH. Do not use command -v inside the
    # alias because otherwise recursion hell will occur every time this script
    # is loaded.
    NANO_ALIAS="nano -AE --tabsize=4"
    export EDITOR="${NANO_ALIAS}"
    export VISUAL="${NANO_ALIAS}"
    # shellcheck disable=SC2139
    alias nano="${NANO_ALIAS}"
}
