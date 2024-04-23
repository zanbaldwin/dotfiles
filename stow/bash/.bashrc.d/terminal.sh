#!/bin/bash

# WARNING!
# If using both Starship and Atuin, then Starship *MUST* be initialized *FIRST*.

# Starship PS1 Prompt
command -v starship >"/dev/null" 2>&1 && {
    eval "$(starship init bash)"
}

# History
command -v "atuin" >"/dev/null" 2>&1 && {
    eval "$(atuin init bash --disable-up-arrow)" 2>"/dev/null"
}
# Up & down map to history search once a command has been started.
bind '"\e[A":history-search-backward' 2>"/dev/null"
bind '"\e[B":history-search-forward' 2>"/dev/null"
# Case-insensitive tab completion
bind 'set completion-ignore-case On' 2>"/dev/null"

alias c="clear"
alias xx="exit"
alias reload=". ~/.bashrc"
# Most installations of `sudo` have `secure_path` enabled, head to `/etc/sudoers` and remove that line.
alias sudo="sudo --preserve-env --"

# Watch the output of the last command instead of having to
# execute it constantly whilst waiting for a different output.
alias follow='watch $(history -p !!)'

# Anger Management
alias fuck='sudo "$SHELL" -c "$(history -p !!)"'
alias fucking="sudo"

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=
