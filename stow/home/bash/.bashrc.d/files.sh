#!/bin/bash

alias cp="cp -riv"
alias mv="mv -iv"
alias ln="ln -v"
alias chmod="chmod -Rv"
alias chown="chown -Rv"
alias rm="rm -v"

export PAGER="less -RFX -c"
alias less="less -S -R -N"
command -v "bat" >"/dev/null" 2>&1 && {
    alias cat="bat --theme=DarkNeon";
    alias less="bat --theme=DarkNeon";
}

# ripgrep is fast, yo.
command -v "rg" >"/dev/null" 2>&1 && {
    alias grep="rg";
}
