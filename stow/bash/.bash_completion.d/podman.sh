#!/usr/bin/env bash

if command -v "podman" >"/dev/null" 2>&1; then
    source <(podman completion bash)
    complete -o default -F __start_podman docker
fi
