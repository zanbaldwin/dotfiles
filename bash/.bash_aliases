#!/bin/bash
# To use this file, symlink it to ~/.bash_aliases (it should already be included
# in ~/.bashrc).

# Problems with common *nix PATHs on macOS.
export PATH="${PATH}:${HOME}/.bin"

# ============= #
# Work Specific #
# ============= #

alias sq="bin/sq-cli/sq"

# ========== #
# Monitoring #
# ========== #

alias gtop="watch -n0.2 nvidia-smi --format=csv --query-gpu=power.draw,utilization.gpu,fan.speed,temperature.gpu"

# ============= #
# Bash-specific #
# ============= #

alias xx="exit"
alias reload=". ~/.bashrc"
alias sudo="sudo --preserve-env"
# Up & down map to history search once a command has been started.
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'
# If a file specifying a custom prompt exists, include it.
if [ -f ~/.bash_prompt ]; then
    . ~/.bash_prompt
fi
alias tmux="tmux attach || tmux new"
# Watch the output of the last command instead of having to
# execute it constantly whilst waiting for a different output.
alias follow='watch $(history -p !!)'

title() { print -Pn "\e]2;$@\a"; }

# ============================= #
# Directory and File Management #
# ============================= #

# Speedup "ls" command by specifying we don't care about the colour
# output based on file permissions.
export LS_COLORS='ex=00:su=00:sg=00:ca=00:'

# Some systems have a version of "ls" that does not have the
# "--group-directories-first" or "-G" command-line flags,
# check for them here before setting the alias.
LL_OPTIONS=""
if ls -G 1>/dev/null 2>&1; then
    LL_OPTIONS="${LL_OPTIONS}G"
fi
if ls --group-directories-first 1>/dev/null 2>&1; then
    LL_OPTIONS="${LL_OPTIONS} --group-directories-first"
fi
alias ll="ls -lAhHp${LL_OPTIONS}"

command -v exa >/dev/null 2>&1 && { alias ll="exa -labUh --git --group-directories-first"; }

alias cp="cp -riv"
alias mv="mv -iv"
alias rmdir="rmdir -v"
alias ln="ln -v"

alias c="clear"
alias ..="cd .."
alias ~="cd ~"
alias cd..="cd .."
alias back="cd -"
alias cdgit='cd $(git rev-parse --show-toplevel)'
alias mkdir="mkdir -pv"
alias chmod="chmod -Rv"
alias chown="chown -Rv"
# See https://github.com/sharkdp/bat/releases
alias rm="rm -v"
function f() {
    find . -name "$1" 2>&1 | grep -v 'Permission denied'
}
function search() {
    grep -l -c -r "$1" .
}

function go() {
    DIR="$(find / -type d 2>/dev/null | grep -v 'Permission denied' | fzy)"
    cd "${DIR}"
}

function edit() {
    FILE="$(find / -type f 2>/dev/null | grep -v 'Permission denied' | fzy)"
    nano "${FILE}"
}

# https://github.com/sharkdp/bat/releases
command -v bat >/dev/null 2>&1 && {
    alias cat="bat --theme=DarkNeon";
    alias less="bat --theme=DarkNeon";
}

# apt install ncdu
command -v "ncdu" >/dev/null 2>&1 && { alias du="ncdu"; }
command -v "duf" >/dev/null 2>&1 && { alias df="duf"; } || {
    command -v df >/dev/null 2>&1 && { alias df="df -h | grep -v snap"; };
}


function create_secure() {
    FOLDER=${1:-"/tmp/secure"}
    sudo mount -t ramfs -o size=1M ramfs "${FOLDER}"
    sudo chown "$(logname):$(logname)" "${FOLDER}"
}
function destroy_secure() {
    FOLDER=${1:-"/tmp/secure"}
    sudo umount "${FOLDER}"
}

command -v "direnv" >/dev/null 2>&1 && {
    eval "$(direnv hook bash)";
}

# ================ #
# Anger Management #
# ================ #

alias fuck='sudo "$SHELL" -c "$(history -p !!)"'
alias fucking="sudo"

# ======= #
# Editors #
# ======= #

command -v nano >/dev/null 2>&1 && {
    # Already know that nano is on the PATH. Do not use command -v inside the
    # alias because otherwise recursion hell will occur every time this script
    # is loaded.
    NANO_ALIAS="nano -AE --tabsize=4"
    export EDITOR="${NANO_ALIAS}"
    export VISUAL="${NANO_ALIAS}"
    alias nano="${NANO_ALIAS}"
}

# Do not word wrap
alias less="less -S -R -N"

alias copy="xclip -sel clip"
alias paste="xclip -out -sel clip"

# ========== #
# Networking #
# ========== #

alias utc='date -u "+%Y%m%dT%H%M%SZ"'
## SSH
alias hosts="cat \"\${HOME}/.ssh/config\" \${HOME}/.ssh/conf.d/* | grep 'Host ' | tr -s ' ' | cut -d' ' -f2 | sort"
alias ssh-config="${EDITOR} \"\${HOME}/.ssh/config\""
## HTTP/S
alias wget="wget -c"
alias mitm="mitmproxy --transparent --host"
command -v "firefox" >/dev/null 2>&1 && { alias fx="firefox --new-instance --profile \"\$(mktemp -d)\""; }
## VPN
alias nord="nordvpn"

command -v "mkcert" >/dev/null 2>&1 && command -v "http" >/dev/null 2>&1 && {
    alias http="http --verify=\"$(mkcert -CAROOT)/rootCA.pem\"";
}

# ========================================================= #
# GnuPG SSH Authentication                                  #
# ========================================================= #
# - Install "gnupg2" and "scdaemon".                        #
# - Add "enable-ssh-support" to "~/.gnupg/gpg-agent.conf"   #
#   - Or copy existing config from this repository          #
# - Find [A]uthentication keygrips "gpg -K --with-keygrip"  #
# - Add appropriate keygrips to "~/.gnupg/sshcontrol"       #
# ========================================================= #

command -v "gpgconf" >/dev/null 2>&1 && {
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)";
    gpgconf --launch gpg-agent;
}

# Sometimes the GPG agent get in a weird state that means that using GPG
# for Git Clone/Push/Pull over SSH stops working.
command -v "gpg-connect-agent" >/dev/null 2>&1 && {
    echo "UPDATESTARTUPTTY" | gpg-connect-agent >/dev/null 2>&1;
}

# ====== #
# Docker #
# ====== #

# Old habits die hard...
alias docker-composer="docker-compose"
docker() {
    if [[ ("$1" = "compose") || ("$1" = "composer") ]]; then
        shift
        command docker-compose $@
    elif [[ "$1" = "machine" ]]; then
        shift
        command docker-machine $@
    else
        command docker $@
    fi
}

alias dterm="echo -it -e \"COLUMNS=\$(tput cols)\" -e \"LINES=\$(tput lines)\" -e TERM=xterm"
alias alpine="docker run --rm \$(dterm) -v \"\$(pwd):\$(pwd)\" -w \"\$(pwd)\" alpine:latest sh"

# === #
# PHP #
# === #

command -v "php" >/dev/null 2>&1 && {
    # Make sure that XDebug is either not enabled or not in mode "debug" in the CLI configuration. If you wish to enable
    # debugging via XDebug while using PHP's CLI SAPI, use the command alias "xdebug" instead.
    alias xdebug='php -dzend_extension=xdebug.so -dxdebug.mode=debug,develop'

    # Vulcan Logic Disassembler
    # To install: `pecl install vld` (currently in beta only, so install vld-beta instead).
    alias vld='php -d vld.active=1 -d vld.execute=0 -d vld.dump_paths=1 -d vld.save_paths=1 -d vld.verbosity=1'

    # Add global Composer package binaries to $PATH.
    command -v "composer" >/dev/null 2>&1 && { export PATH="${PATH}:$(composer global config bin-dir --absolute 2>/dev/null)"; }
}

# ========= #
# Rust Lang #
# ========= #

[ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"

# =============== #
# Auto-completion #
# =============== #

## AWS
command -v "aws_completer" >/dev/null 2>&1 && { complete -C "$(command -v aws_completer 2>/dev/null)" aws; }

## Mobile Secure Shell
command -v "mosh" >/dev/null 2>&1 && {
    SSHC="$(complete -p ssh 2>/dev/null)" && {
        # Use the same bash-completion rules for Mosh as are registered to SSH.
        $SSHC mosh
    }
}
