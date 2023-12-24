#!/usr/bin/env bash

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

if command -v "exa" >"/dev/null" 2>&1; then
    alias ll="exa -labUh --git --group-directories-first --icons";
else
    # shellcheck disable=SC2139
    alias ll="ls -lAhHp${LL_OPTIONS}";
fi

# Try it out on Linux first before putting in install-rust.sh
command -v "zoxide" >"/dev/null" 2>&1 && {
    eval "$(zoxide init bash --no-cmd)";
}
## Git Repository Information on Directory Change
if command -v "onefetch" >"/dev/null" 2>&1 && command -v "git" >"/dev/null" 2>&1; then
    LAST_REPO=""
    function cd {
        if [[ "$(type -f __zoxide_z 2>/dev/null)" == "function" ]]; then
            # TODO: Don't think this is working very well. Dive into zoxide src and
            #       Bash initialisation script when you have the time.
            __zoxide_z "$@" || return;
        else
            builtin cd "$@" || return;
        fi

        if git rev-parse --show-toplevel >"/dev/null" 2>&1; then
            NEW_REPO="$(git rev-parse --show-toplevel 2>"/dev/null")"
            if [ "${LAST_REPO}" != "${NEW_REPO}" ]; then
                onefetch
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
