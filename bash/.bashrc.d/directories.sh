#!/bin/bash

# Some systems have a version of "ls" that does not have the
# "--group-directories-first" or "-G" command-line flags,
# check for them here before setting the alias.
LL_OPTIONS=""
if ls -G >"/dev/null" 2>&1; then
    LL_OPTIONS="${LL_OPTIONS}G"
fi
if ls --group-directories-first >"/dev/null" 2>&1; then
    LL_OPTIONS="${LL_OPTIONS} --group-directories-first"
fi

command -v "exa" >"/dev/null" 2>&1 && {
    alias ll="exa -labUh --git --group-directories-first";
} || {
    # shellcheck disable=SC2139
    alias ll="ls -lAhHp${LL_OPTIONS}";
};

## Git Repository Information on Directory Change
if command -v "onefetch" >"/dev/null" 2>&1 && command -v "git" >"/dev/null" 2>&1; then
    LAST_REPO=""
    function cd() {
        # shellcheck disable=SC2068
        builtin cd $@ || return
        if git rev-parse --show-toplevel >"/dev/null" 2>&1; then
            NEW_REPO="$(git rev-parse --show-toplevel 2>"/dev/null")"
            if [ "${LAST_REPO}" != "${NEW_REPO}" ]; then
                onefetch --show-logo="auto"
                LAST_REPO="${NEW_REPO}"
            fi
        fi
    }
fi

command -v "ncdu" >"/dev/null" 2>&1 && {
    alias du="ncdu";
}

command -v "direnv" >/dev/null 2>&1 && {
    eval "$(direnv hook bash)";
}

alias rmdir="rmdir -v"
alias ..="cd .."
alias ~="cd ~"
alias cd..="cd .."
alias back="cd -"
alias cdgit='cd $(git rev-parse --show-toplevel)'
alias mkdir="mkdir -pv"
