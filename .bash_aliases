# To use this file, symlink it to ~/.bash_aliases (it should already be included
# in ~/.bashrc).

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
alias less="less -S -R"

# Watch the output of the last command instead of having to
# execute it constantly whilst waiting for a different output.
alias follow='watch $(history -p !!)'

# ============================= #
# Directory and File Management #
# ============================= #

# Some systems have a version of "ls" that does not have the
# "--group-directories-first" command-line flag, check for it
# here before setting the alias.
ls -lAh --color=auto --group-directories-first 1>/dev/null 2>&1
if [ $? -eq 1 ]; then
    alias ll="ls -lAh --color=auto"
else
    alias ll="ls -lAh --color=auto --group-directories-first"
fi

alias c="clear"
alias ..="cd .."
alias ~="cd ~"
alias cd..="cd .."
alias back="cd -"
alias mkdir="mkdir -pv"
alias chmod="chmod -Rv"
alias chown="chown -Rv"
# See https://github.com/sharkdp/bat/releases
alias cat="bat --theme=DarkNeon"
alias rm="rm -v"
function f() {
    find . -name "$1" 2>&1 | grep -v 'Permission denied'
}
function search() {
    grep -l -c -r "$1" .
}
which trash >/dev/null 2>&1
if [ $? -eq 0 ]; then
    alias rm="trash -v"
fi

# Fuzzy Finder
# (git clone --depth 1 https://github.com/junegunn/fzf.git /opt/fzf && /opt/fzf/install)
#   - CTRL-R: Search through command history.
#   - CTRL-T: Search and insert filename at cursor
#   - ALT-C:  Search and change to directory.
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
alias fzf="fzf-tmux"

# apt install ncdu
alias du="ncdu"

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

alias m="make"
alias nano="nano -AES --tabsize=4"
alias n="nano -AES --tabsize=4"
alias vim="vim -N"
alias v="vim -N"

# ========== #
# Networking #
# ========== #

# See https://github.com/denilsonsa/prettyping
alias ping="prettyping --nolegend"
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

# ========================================================= #
# GnuPG SSH Authentication                                  #
# ========================================================= #
# - Install "gnupg2" and "scdaemon".                        #
# - Add "enable-ssh-support" to "~/.gnupg/gpg-agent.conf"   #
#   - Or copy existing config from this repository          #
# - Find [A]uthentication keygrips "gpg -K --with-keygrip"  #
# - Add appropriate keygrips to "~/.gnupg/sshcontrol"       #
# ========================================================= #

which gpgconf 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    gpgconf --launch gpg-agent
fi

# ======= #
# Vagrant #
# ======= #

alias vssh="vagrant ssh"
alias vsync="vagrant rsync"

# For the following shortcut to the VM DB, you will need:
#  mysql-client, .dev DNSMasq config, a working VM, all privileges granted to "root@%".
alias bksql="mysql -u root -h basekit.dev basekit"

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

alias v1="docker-compose -f docker-compose.yml"
alias v2="docker-compose -f docker-compose-v2.yml"
alias v2-php="docker-compose -f docker-compose-v2.yml run --rm php"
alias v3="docker-compose -f docker-compose-v3.yml"
alias v3-php="docker-compose -f docker-compose-v3.yml run --rm php"
alias v4="docker-compose -f docker-compose-v4.yml"
alias v4-php="docker-compose -f docker-compose-v4.yml run --rm php"
alias v5="docker-compose -f docker-compose-v5.yml"
alias v5-php="docker-compose -f docker-compose-v5.yml run --rm php"

# === #
# PHP #
# === #

PHP=$(which php)
if [ $? -eq 0 ]; then

    # Make sure that XDebug is installed but not enabled in the CLI configuration. This will make
    # sure that running commands like "composer" will NOT use XDebug, but commands like "php ..."
    # WILL use XDebug.
    # You need the php-dev package (php5-dev, php7.0-dev, etc) installed to use "php-config".
    which php-config 1>/dev/null 2>&1
    if [ $? -eq 0 ] && [ -f "$(php-config --extension-dir)/xdebug.so" ]; then
        alias php="$PHP -dzend_extension=xdebug.so"
    fi

    # Vulcan Logic Disassembler
    # To install: `pecl install vld` (currently in beta only, so install vld-beta instead).
    alias vld='php -d vld.active=1 -d vld.execute=0 -d vld.dump_paths=1 -d vld.save_paths=1 -d vld.verbosity=0'

    # Add global Composer package binaries to $PATH.
    COMPOSER=$(which composer)
    if [ $? -eq 0 ]; then
        export PATH="${PATH}:$(composer global config bin-dir --absolute 2>/dev/null)"
    fi

    # For parallel package downloading in Composer (!!!) install the following global package:
    #     $ composer global require hirak/prestissimo
    # Now that we have Composer package binaries on the PATH, install the useful CGR package:
    #     $ composer global require consolidation/cgr
    # Then install some useful packages:
    #     $ cgr bamarni/symfony-console-autocomplete
    #     $ cgr phpunit/phpunit
    #     $ cgr squizlabs/php_codesniffer
    # And then initialise them:

    SYMAUTOPATH=$(which symfony-autocomplete)
    if [ $? -eq 0 ]; then
        eval "$($SYMAUTOPATH)"
    fi

    # PHPUnit (this enables XDebug automatically on the CLI).
    PHPUNIT=$(which phpunit)
    if [ $? -eq 0 ]; then
        alias phpunit="php $PHPUNIT"
    fi

    # Puli Universal Packages Manager.
    PULI=$(which puli)
    if [ $? -eq 0 ]; then
        alias puli='set -f;puli';puli(){ command puli "$@";set +f;}
    fi

fi

# PHP Environment.
# Use this to provision a PHP environment (useful when current OS does not support a high
# enough version of PHP for the project). Defaults to the latest PHP version using Alpine
# Linux (checks for new versions on each run). Specify the VERSION environment variable
# for a different PHP version (eg: `VERSION=5.6 phpenv`). Can also be used to
# provision other environments like Ruby or NodeJS (eg: `IMAGE=node phpenv`).
function phpenv {
    local DOCKER=${DOCKER:-"docker"}
    command -v "${DOCKER}" >/dev/null 2>&1 || { echo >&2 "$(tput setaf 1)Docker Client \"${DOCKER}\" not installed.$(tput sgr0)"; return 1; }

    local INFO=$("${DOCKER}" info >/dev/null 2>&1)
    if [ $? -ne 0 ]; then
        echo >&2 "$(tput setaf 1)Docker Daemon unavailable. Aborting!$(tput sgr0)"
        if [ "$(id -u 2>/dev/null)" -ne "0" ]; then
            echo >&2 "$(tput setaf 1)Perhaps retry as root?$(tput sgr0)"
        fi
        return 1
    fi

    local IMAGE=${IMAGE:-"php"}
    local VERSION=${VERSION:-"alpine"}

    local CACHE=""
    local COMPOSER="$(which composer 2>/dev/null)"
    if [ "${COMPOSER}" != "" ]; then
        local COMPOSER="-v \"${COMPOSER}:/bin/composer\""
        local COMPOSER_HOME_DIR="$(composer global config home 2>/dev/null)"
        if [ $? -eq 0 ] && [ -d "${COMPOSER_HOME_DIR}" ]; then
            local CACHE="-v \"${COMPOSER_HOME_DIR}:/.composer\" -e \"COMPOSER_HOME=/.composer\""
        fi
    fi

    echo "$(tput setaf 2)Checking for newer version of \"${IMAGE}:${VERSION}\" on Docker Hub.$(tput setaf 6)"
    docker pull "${IMAGE}:${VERSION}" 2>/dev/null || echo >&2 "$(tput setaf 1)Could not connect to Docker Hub. Skipping update."
    echo "$(tput sgr0)"

    local PHPENV="docker run -it --rm -v \"$(pwd):$(pwd)\" -w \"$(pwd)\" $CACHE $COMPOSER -u \"$(id -u):$(id -g)\" -e \"TERM=xterm\" \"${IMAGE}:${VERSION}\""
    $SHELL -c "${PHPENV} sh"
}

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

# =============== #
# Auto-completion #
# =============== #

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
