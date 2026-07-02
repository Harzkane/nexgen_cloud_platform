#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Provider: Group
# ============================================================

set -euo pipefail

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PROVIDER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/users.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"

# Returns present | absent
resource_group_state() {
    local groupname="$1"
    if is_group_exists "$groupname"; then
        echo "present"
    else
        echo "absent"
    fi
}

# Returns SATISFIED | MISSING
resource_group_diff() {
    local groupname="$1"
    local desired="${2:-present}"

    local live
    live=$(resource_group_state "$groupname")

    if [ "$live" = "$desired" ]; then
        echo "SATISFIED"
    else
        echo "MISSING"
    fi
}

# Apply desired state to target group
resource_group_apply() {
    local groupname="$1"
    local desired="${2:-present}"
    local comp_id="${3:-}"

    local live
    live=$(resource_group_state "$groupname")

    if [ "$live" = "$desired" ]; then
        log_info "Group '$groupname' is already $desired."
        return 0
    fi

    if [ "$desired" = "present" ]; then
        log_info "Creating group '$groupname'..."
        if create_group "$groupname"; then
            record_transaction_item "group" "$groupname" "created" "$comp_id"
            return 0
        fi
    elif [ "$desired" = "absent" ]; then
        log_info "Deleting group '$groupname'..."
        local os
        os=$(uname -s)
        if [ "$os" = "Darwin" ]; then
            sudo dscl . -delete "/Groups/$groupname" >/dev/null 2>&1 || true
        else
            sudo groupdel "$groupname" >/dev/null 2>&1 || true
        fi
        record_transaction_item "group" "$groupname" "deleted" "$comp_id"
        return 0
    fi
    return 1
}
