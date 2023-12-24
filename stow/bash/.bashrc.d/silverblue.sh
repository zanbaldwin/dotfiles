#!/bin/bash

alias bases='ostree remote refs fedora | grep --no-messages --color="never" "x86_64/silverblue"'
alias switch-base='rpm-ostree rebase --os="fedora" --remote="fedora" --branch'
alias update='rpm-ostree upgrade --check'
alias upgrade='rpm-ostree upgrade'
