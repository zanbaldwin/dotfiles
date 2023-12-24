#!/bin/bash

alias wget="wget -c"
alias mitm="mitmproxy --transparent --host"
alias nord="nordvpn"
command -v "firefox" >"/dev/null" 2>&1 && {
    alias fx="firefox --new-instance --profile \"\$(mktemp -d)\"";
}
