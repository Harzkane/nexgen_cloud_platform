#!/usr/bin/env bash

set -euo pipefail

get_os_name() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "$PRETTY_NAME"
    else
        uname -s
    fi
}

get_kernel() {
    uname -r
}

get_architecture() {
    uname -m
}