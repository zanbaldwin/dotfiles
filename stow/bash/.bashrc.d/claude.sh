#!/usr/bin/env bash

if command -v 'claude' >'/dev/null' 2>&1; then
    cc() {
        local PR_LINK="${1}"
        export CLAUDE_CODE_DISABLE_AUTO_MEMORY=0
        export CLAUDE_CODE_NEW_INIT=1
        export CLAUDE_CODE_NO_FLICKER=1
        if [ ! -z "${PR_LINK}" ]; then
            claude --no-chrome --from-pr="${PR_LINK}";
        else
            claude --no-chrome;
        fi
    }
fi
