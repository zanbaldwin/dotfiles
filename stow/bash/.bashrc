# Source global definitions
if [ -f "/etc/bashrc" ]; then
    . "/etc/bashrc"
fi

# User specific aliases and functions
if [ -d "${HOME}/.bashrc.d" ]; then
    for RC in "${HOME}/.bashrc.d/"*; do
        if [ -f "${RC}" ]; then
            . "${RC}"
        fi
    done
fi
unset RC
