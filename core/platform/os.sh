#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# OS Abstraction Service
# ============================================================

set -euo pipefail

# Query operating system name (e.g. Darwin, Linux)
get_os_name() {
    uname -s
}

# Query system architecture (e.g. x86_64, arm64)
get_architecture() {
    uname -m
}

# Query the init system (e.g. systemd, launchd, unknown)
get_init_system() {
    local os
    os=$(get_os_name)
    if [ "$os" = "Darwin" ]; then
        echo "launchd"
    elif [ "$os" = "Linux" ]; then
        if command -v systemctl >/dev/null 2>&1; then
            echo "systemd"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}
