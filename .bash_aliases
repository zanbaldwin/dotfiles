# To use this file, symlink it to ~/.bash_aliases (it should already be included
# in ~/.bashrc).

# ============= #
# Bash-specific #
# ============= #

# Up & down map to history search once a command has been started.
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# If a file specifying a custom prompt exists, include it.
if [ -f ~/.bash_prompt ]; then
    . ~/.bash_prompt
fi

# ==================== #
# Directory Management #
# ==================== #

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
alias rm="rm -I --preserve-root -v"
function f() {
    find . -name "$1" 2>&1 | grep -v 'Permission denied'
}
function search() {
    grep -l -c -r "$1" .
}

# ================ #
# Anger Management #
# ================ #

alias fuck='sudo "$SHELL" -c "$(history -p !!)"'
alias fucking="sudo"

# ======= #
# Editors #
# ======= #

alias nano="nano -AES --tabsize=4"
alias n="nano -AES --tabsize=4"
alias vim="vim -N"
alias v="vim -N"

# ========== #
# Networking #
# ========== #

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
    if [[ ($1 = "compose") || ($1 = "composer") ]]; then
        shift
        command docker-compose $@
    else
        command docker $@
    fi
}

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
    export PATH="$PATH:$HOME/.config/composer/vendor/bin:$HOME/.composer/vendor/bin"

    # For parallel package downloading in Composer (!!!) install the following global package:
    #     $ composer global require hirak/prestissimo
    # Now that we have Composer package binaries on the PATH, install the useful CGR package:
    #     $ composer global require consolidation/cgr
    # Then install some useful packages:
    #     $ cgr bamarni/symfony-console-autocomplete
    #     $ cgr phpunit/phpunit
    #     $ cgr squizlabs/php_codesniffer
    #     $ cgr puli/cli
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

# ======== #
# Go! Lang #
# ======== #

export GOROOT="/usr/local/go"
export GOPATH="$HOME/code/golang"
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"

# =============== #
# Auto-completion #
# =============== #

## These are not meant to be executed every time a new Bash environment is created, instead they
## are helpful reminders to set up autocompletion on a new system. Most assume that the associated
## tool has already been installed.

## Docker Compose
# sudo curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

## Kompose
# sudo "$SHELL" -c "kompose completion bash > /etc/bash_completion.d/kompose"

## AWS (might take a while to complete)
# sudo cp -s $(find / -name aws_completer 2>/dev/null | head -n1) /etc/bash_completion.d/aws
