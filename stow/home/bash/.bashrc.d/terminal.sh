#!/bin/bash

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
# Most installations of `sudo` have `secure_path` enabled, head to `/etc/sudoers` and remove that line.
alias sudo="sudo --preserve-env --"

# Watch the output of the last command instead of having to
# execute it constantly whilst waiting for a different output.
alias follow='watch $(history -p !!)'

alias tmux="tmux attach || tmux new"

# Anger Management
alias fuck='sudo "$SHELL" -c "$(history -p !!)"'
alias fucking="sudo"
