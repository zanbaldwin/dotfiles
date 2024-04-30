#!/usr/bin/env bash

THIS_DIR="$(dirname "$(readlink -f "$0")")"

# Installation scripts that work on the host, rather than a toolbox container.
bash "${THIS_DIR}/toolbox/fonts.sh"
bash "${THIS_DIR}/toolbox/dconf.sh"
bash "${THIS_DIR}/toolbox/flakpak.sh"

toolbox create rust \
    && toolbox run --container="rust" bash "${THIS_DIR}/toolbox/rust.sh" \
    && toolbox run --container="rust" bash "${THIS_DIR}/toolbox/zellij.sh"
toolbox run --container="rust" bash "${THIS_DIR}/toolbox/alacritty.sh" \
    && sudo cp -r "${HOME}/.cache/alacritty/"* "/usr/" \
    && rm -rf "${HOME}/.cache/alacritty"

toolbox create php \
    && toolbox run --container="php" bash "${THIS_DIR}/toolbox/php.sh"

toolbox create stow \
    && toolbox run --container="stow" bash "${THIS_DIR}/toolbox/stow.sh"

if command -v "docker-compose" >"/dev/null" 2>&1; then
    (cd "${HOME}/code"; DOCKER_HOST="" sudo docker-compose up -d)
fi

if command -v "mkcert" >"/dev/null" 2>&1; then
    mkcert -install
    sudo mkcert -install
    mkcert \
        -cert-file "${HOME}/code/stack.crt" \
        -key-file "${HOME}/code/stack.key" \
        "proxy.test" \
        "mailhog.test" \
        "ollama.test" \
        "jupyter.test"
    echo "# Local Stack" | sudo tee "/etc/hosts"
    echo "127.0.0.1 proxy.test mailhog.test ollama.test jupyter.test" | sudo tee "/etc/hosts"
fi

# Things to do afterwards:
# - Copy and/or generate SSH Keys and Config
# - Proxy entries for local stack.
