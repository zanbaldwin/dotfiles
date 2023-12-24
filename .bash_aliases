alias vssh="vagrant ssh"
alias vsync="vagrant rsync"
alias ll="ls -lAh --color=auto --group-directories-first"

alias c="clear"
alias ..="cd .."
alias ~="cd ~"
alias cd..="cd .."
alias back="cd -"
alias mkdir="mkdir -pv"
alias chmod="chmod -Rv"
alias chown="chown -Rv"
alias nano="nano -AES --tabsize=4"
alias n="nano -AES --tabsize=4"
alias rm="rm -I --preserve-root -v"
# alias rm="trash"
alias wget="wget -c"
alias fuck='sudo "$BASH" -c "$(history -p !!)"'
alias fucking="sudo"
alias vim="vim -N"
alias v="vim -N"
alias docker-composer="docker-compose"

alias dig="dig +nocmd any +multiline +noall +answer"

# Up & down map to history search once a command has been started.
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
    alias "$method"="lwp-request -m '$method'"
done

docker() {
    if [[ ($1 = "compose") || ($1 = "composer") ]]; then
        shift
        command docker-compose $@
    else
        command docker $@
    fi
}

function f() {
    find . -name "$1" 2>&1 | grep -v 'Permission denied'
}

function search() {
    grep -l -c -r "$1" .
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
    local port="${1:-8000}"
    open "http://localhost:${port}/"
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
    # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

function whois() {
    local domain=$(echo "$1" | awk -F/ '{print $3}') # get domain from URL
    if [ -z $domain ] ; then
        domain=$1
    fi
    echo "Getting whois record for: $domain …"

    # avoid recursion
                    # this is the best whois server
                                                    # strip extra fluff
    /usr/bin/whois -h whois.internic.net $domain | sed '/NOTICE:/q'
}
