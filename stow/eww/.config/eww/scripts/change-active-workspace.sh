#!/bin/bash

function clamp {
	MIN=$1
	MAX=$2
	VAL=$3
	python3 -c "print(max(${MIN}, min(${VAL}, ${MAX})))"
}

DIRECTION=$1
CURRENT=$2
if test "$DIRECTION" = "down"; then
	TARGET="$(clamp 1 10 $(($CURRENT+1)))"
	echo "Switching to Workspace #${TARGET}"
	hyprctl dispatch workspace $TARGET
elif test "$DIRECTION" = "up"; then
	TARGET="$(clamp 1 10 $(($CURRENT-1)))"
	echo "Switching to Workspace #${TARGET}"
	hyprctl dispatch workspace "${TARGET}"
fi
