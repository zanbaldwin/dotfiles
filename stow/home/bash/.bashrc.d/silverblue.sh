#!/bin/bash

alias bases='ostree remote refs fedora | grep -v "updates" | grep --no-messages --color="never" "$(uname -m)"'
alias switch-base='rpm-ostree rebase --os="fedora" --remote="fedora" --branch'
alias update='rpm-ostree upgrade --check'
alias upgrade='rpm-ostree upgrade'
alias list-packages='rpm -qa'
