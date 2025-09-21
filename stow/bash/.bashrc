# Learnt the hard way: install ble.sh as directed and reference; do not include copy in dotfiles.
[[ $- == *i* ]] && [ -f "${HOME}/.local/share/blesh/ble.sh" ] && source "${HOME}/.local/share/blesh/ble.sh" --attach=none --rcfile="${HOME}/.config/bash/.blerc"

# Source global definitions
[ -f "/etc/bashrc" ] && source "/etc/bashrc"
[ -f "/etc/bash.bashrc" ] && source "/etc/bash.bashrc"

[ -f "${HOME}/.bash_aliases" ] && source "${HOME}/.bash_aliases"
[ -f "${HOME}/.bash_completion" ] && source "${HOME}/.bash_completion"

[[ ${BLE_VERSION-} ]] && ble-attach
