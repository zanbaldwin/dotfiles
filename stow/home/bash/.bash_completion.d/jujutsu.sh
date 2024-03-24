#!/usr/bin/env bash

if command -v "jj" >"/dev/null" 2>&1; then
    source <(jj util completion bash)
fi
