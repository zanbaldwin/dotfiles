#!/bin/bash

# Up & down map to history search once a command has been started.
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# Starship PS1 Prompt
command -v starship >"/dev/null" 2>&1 && {
    eval "$(starship init bash)"
}

# Speedup "ls" command by specifying we don't care about the colour
# output based on file permissions.
export LS_COLORS='ex=00:su=00:sg=00:ca=00:'

alias c="clear"
alias xx="exit"
alias reload=". ~/.bashrc"
alias sudo="sudo --preserve-env"

# Watch the output of the last command instead of having to
# execute it constantly whilst waiting for a different output.
alias follow='watch $(history -p !!)'

title() { print -Pn "\e]2;$@\a"; }

alias tmux="tmux attach || tmux new"

# Anger Management
alias fuck='sudo "$SHELL" -c "$(history -p !!)"'
alias fucking="sudo"
