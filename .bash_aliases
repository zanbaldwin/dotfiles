#!/bin/bash
# To use this file, symlink it to ~/.bash_aliases (it should already be included
# in ~/.bashrc).

# Problems with common *nix PATHs on macOS.
export PATH="${PATH}:${HOME}/.bin"

# ============= #
# Bash-specific #
# ============= #

alias reload=". ~/.bashrc"
alias sudo="sudo --preserve-env"

# Up & down map to history search once a command has been started.
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# If a file specifying a custom prompt exists, include it.
if [ -f ~/.bash_prompt ]; then
    . ~/.bash_prompt
fi

# Do not word wrap
alias less="less -S -R -N"
alias tmux="tmux attach || tmux new"

# Watch the output of the last command instead of having to
# execute it constantly whilst waiting for a different output.
alias follow='watch $(history -p !!)'

alias xx="exit"
alias hosts="cat '${HOME}/.ssh/config' | grep 'Host ' | cut -d' ' -f2 | sort"
alias ssh-config="nano ${HOME}/.ssh/config"

title() { print -Pn "\e]2;$@\a"; }

# Speedup "ls" command by specifying we don't care about the colour
# output based on file permissions.
export LS_COLORS='ex=00:su=00:sg=00:ca=00:'

# ============================= #
# Directory and File Management #
# ============================= #

# Some systems have a version of "ls" that does not have the
# "--group-directories-first" or "-G" command-line flags,
# check for them here before setting the alias.
LL_OPTIONS=""
ls -G 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    LL_OPTIONS="${LL_OPTIONS}G"
fi
ls --group-directories-first 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    LL_OPTIONS="${LL_OPTIONS} --group-directories-first"
fi
alias ll="ls -lAhHp${LL_OPTIONS}"

# https://github.com/ogham/exa/releases
command -v exa >/dev/null 2>&1 && { alias ll="exa -labUh --git --group-directories-first"; }

alias cp="cp -iv"
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

# https://github.com/sharkdp/bat/releases
command -v bat >/dev/null 2>&1 && { alias cat="bat --theme=DarkNeon"; }

command -v trash >/dev/null 2>&1 && { alias rm="trash -v"; }

# Fuzzy Finder
# (git clone --depth 1 https://github.com/junegunn/fzf.git /opt/fzf && /opt/fzf/install)
#   - CTRL-R: Search through command history.
#   - CTRL-T: Search and insert filename at cursor
#   - ALT-C:  Search and change to directory.
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
alias fzf="fzf-tmux"

# apt install ncdu
command -v ncdu >/dev/null 2>&1 && { alias du="ncdu"; }

function create_secure() {
    FOLDER=${1:-"/tmp/secure"}
    sudo mount -t ramfs -o size=1M ramfs "${FOLDER}"
    sudo chown "$(logname):$(logname)" "${FOLDER}"
}
function destroy_secure() {
    FOLDER=${1:-"/tmp/secure"}
    sudo umount "${FOLDER}"
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
    NANO_FLAGS="-AE --tabsize=4"
    alias nano="nano ${NANO_FLAGS}"
    export EDITOR="$(command -v nano 2>/dev/null) ${NANO_FLAGS}"
    export VISUAL="${EDITOR}"
}

alias vim="vim -N"

# ========== #
# Networking #
# ========== #

alias utc='date -u "+%Y%m%dT%H%M%SZ"'

# See https://github.com/denilsonsa/prettyping
command -v prettyping >/dev/null 2>&1 && { alias ping="prettyping --nolegend"; }
alias wget="wget -c"
alias mitm="mitmproxy --transparent --host"
alias dig="dig +nocmd any +multiline +noall +answer"
# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
    alias "$method"="lwp-request -m '$method'"
done
function whois() {
    local WHOIS=$(which whois)
    if [ $WHOIS != "" ]; then
        # Get domain from URL
        local DOMAIN=$(echo "$1" | awk -F/ '{print $3}')
        if [ -z $DOMAIN ]; then DOMAIN=$1; fi
        echo "Getting whois record for: $DOMAIN …"
        $WHOIS -h whois.internic.net $DOMAIN | sed '/NOTICE:/q'
    fi
}

alias freenode="irssi --connect=chat.freenode.net --nick=ZanBaldwin"
alias fx="firefox --new-instance --profile $(mktemp -d)"

command -v mycli >/dev/null 2>&1 && { alias mysql="mycli"; }
command -v pgcli >/dev/null 2>&1 && {
    alias psql="pgcli";
    alias pgsql="pgcli";
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

command -v gpgconf >/dev/null 2>&1 && {
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)";
    gpgconf --launch gpg-agent;
}

# Sometimes the GPG agent get in a weird state that means that using GPG
# for Git Clone/Push/Pull over SSH stops working.
command -v gpg-connect-agent >/dev/null 2>&1 && {
    echo UPDATESTARTUPTTY | gpg-connect-agent >/dev/null 2>&1;
}

# ======= #
# Vagrant #
# ======= #

alias vssh="vagrant ssh"
alias vsync="vagrant rsync"

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

alias dterm="echo -it -e COLUMNS=$(tput cols) -e LINES=$(tput lines) -e TERM=xterm"
alias alpine="docker run --rm $(dterm) -v \"$(pwd):$(pwd)\" -w \"$(pwd)\" alpine:latest sh"

# === #
# PHP #
# === #

PHP=$(which php)
if [ $? -eq 0 ]; then

    # Make sure that XDebug is installed but not enabled in the CLI configuration. This will make
    # sure that running commands like "composer" will NOT use XDebug, but commands like "php ..."
    # WILL use XDebug.
    # You need the php-dev package (php5-dev, php7.0-dev, etc) installed to use "php-config".
    if command -v php-config >/dev/null 2>&1 && [ -f "$(php-config --extension-dir)/xdebug.so" ]; then
        alias php="${PHP} -dzend_extension=xdebug.so"
    fi

    # Vulcan Logic Disassembler
    # To install: `pecl install vld` (currently in beta only, so install vld-beta instead).
    alias vld='php -d vld.active=1 -d vld.execute=0 -d vld.dump_paths=1 -d vld.save_paths=1 -d vld.verbosity=0'

    # Add global Composer package binaries to $PATH.
    command -v composer >/dev/null 2>&1 && { export PATH="${PATH}:$(composer global config bin-dir --absolute 2>/dev/null)"; }

    # For parallel package downloading in Composer (!!!) install the following global package:
    #     $ composer global require hirak/prestissimo
    # Now that we have Composer package binaries on the PATH, install the useful CGR package:
    #     $ composer global require consolidation/cgr
    # Then install some useful packages:
    #     $ cgr bamarni/symfony-console-autocomplete
    #     $ cgr phpunit/phpunit
    #     $ cgr squizlabs/php_codesniffer
    # And then initialise them:

    SYMAUTOPATH=$(command -v symfony-autocomplete 2>/dev/null)
    if [ $? -eq 0 ]; then
        eval "$($SYMAUTOPATH)"
    fi

    # PHPUnit (this enables XDebug automatically on the CLI).
    command -v phpunit >/dev/null 2>&1 && { alias phpunit="php $PHPUNIT"; }

fi

# ======== #
# Go! Lang #
# ======== #

export GOROOT="/usr/local/go"
export GOPATH="${HOME}/code/golang"
export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"

# ====== #
# NodeJS #
# ====== #

export PATH="${HOME}/.yarn/bin:${HOME}/.config/yarn/global/node_modules/.bin:${PATH}"

# ========= #
# Rust Lang #
# ========= #

[ -f "~/.cargo/env" ] && . "~/.cargo/env"

# =============== #
# Auto-completion #
# =============== #

which mosh >/dev/null 2>&1
if [ $? -eq 0 ]; then
    SSHC="$(complete -p ssh 2>/dev/null)"
    if [ $? -eq 0 ]; then
        # Use the same bash-completion rules for Mosh as are registered to SSH.
        $SSHC mosh
    fi
fi

## These are not meant to be executed every time a new Bash environment is created, instead they
## are helpful reminders to set up autocompletion on a new system. Most assume that the associated
## tool has already been installed.

## Kubernetes Autocompletion
# kubectl copmletion bash | sudo tee /etc/bash_completion.d/kubectl

## Docker Compose
# sudo curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

## Kompose
# sudo "$SHELL" -c "kompose completion bash > /etc/bash_completion.d/kompose"

## AWS (might take a while to complete)
# sudo cp -s $(find / -name aws_completer 2>/dev/null | head -n1) /etc/bash_completion.d/aws
