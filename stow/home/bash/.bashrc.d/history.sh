#!/usr/bin/env bash

command -v "atuin" >"/dev/null" 2>&1 && {
    eval "$(atuin init bash --disable-up-arrow)" 2>"/dev/null"
}

# Up & down map to history search once a command has been started.
bind '"\e[A":history-search-backward' 2>"/dev/null"
bind '"\e[B":history-search-forward' 2>"/dev/null"
