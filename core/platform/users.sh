#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Users and Groups Abstraction Service
# ============================================================

set -euo pipefail

USERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$USERS_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/os.sh"

is_user_exists() {
    id "$1" >/dev/null 2>&1 && return 0 || return 1
}

is_group_exists() {
    getent group "$1" >/dev/null 2>&1 && return 0 || return 1
}

create_user() {
    local username="$1"
    local shell="${2:-/bin/bash}"
    local home_dir="${3:-}"
    local os
    os=$(get_os_name)

    if is_user_exists "$username"; then
        log_info "User '$username' already exists."
        return 0
    fi

    log_info "Creating user '$username' on $os..."
    if [ "$os" = "Darwin" ]; then
        # macOS user creation
        sudo sysadminctl -addUser "$username" -shell "$shell" ${home_dir:+-home "$home_dir"} >/dev/null 2>&1 || true
    else
        # Linux user creation
        local -a args=("-s" "$shell")
        if [ -n "$home_dir" ]; then
            args+=("-d" "$home_dir" "-m")
        fi
        sudo useradd "${args[@]}" "$username"
    fi
}

create_group() {
    local groupname="$1"
    local os
    os=$(get_os_name)

    if is_group_exists "$groupname"; then
        log_info "Group '$groupname' already exists."
        return 0
    fi

    log_info "Creating group '$groupname' on $os..."
    if [ "$os" = "Darwin" ]; then
        # macOS group creation via dscl
        sudo dscl . -create "/Groups/$groupname"PrimaryGroupID 1000 || true
    else
        # Linux group creation
        sudo groupadd "$groupname"
    fi
}
