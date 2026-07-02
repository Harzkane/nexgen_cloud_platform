#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Provider: User
# ============================================================

set -euo pipefail

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PROVIDER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/users.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"

# Returns present | absent
resource_user_state() {
    local username="$1"
    if is_user_exists "$username"; then
        echo "present"
    else
        echo "absent"
    fi
}

# Returns SATISFIED | MISSING
resource_user_diff() {
    local username="$1"
    local desired="${2:-present}"

    local live
    live=$(resource_user_state "$username")

    if [ "$live" = "$desired" ]; then
        echo "SATISFIED"
    else
        echo "MISSING"
    fi
}

# Apply desired state to target user
# Extra fields: shell, home_dir
resource_user_apply() {
    local username="$1"
    local desired="${2:-present}"
    local comp_id="${3:-}"
    local shell="${4:-/bin/bash}"
    local home_dir="${5:-}"

    local live
    live=$(resource_user_state "$username")

    if [ "$live" = "$desired" ]; then
        log_info "User '$username' is already $desired."
        return 0
    fi

    if [ "$desired" = "present" ]; then
        log_info "Creating user '$username'..."
        if create_user "$username" "$shell" "$home_dir"; then
            record_transaction_item "user" "$username" "created" "$comp_id"
            return 0
        fi
    elif [ "$desired" = "absent" ]; then
        log_info "Deleting user '$username'..."
        local os
        os=$(uname -s)
        if [ "$os" = "Darwin" ]; then
            sudo sysadminctl -deleteUser "$username" >/dev/null 2>&1 || true
        else
            sudo userdel -r "$username" >/dev/null 2>&1 || true
        fi
        record_transaction_item "user" "$username" "deleted" "$comp_id"
        return 0
    fi
    return 1
}
