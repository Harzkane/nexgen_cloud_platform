#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Provider: Symlink
# ============================================================

set -euo pipefail

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PROVIDER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/filesystem.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"

# Returns present | absent
resource_symlink_state() {
    local path="$1"
    if [ -L "$path" ]; then
        echo "present"
    else
        echo "absent"
    fi
}

# Returns SATISFIED | MISSING | DRIFTED
resource_symlink_diff() {
    local path="$1"
    local desired="${2:-present}"
    local target="${3:-}"

    local live
    live=$(resource_symlink_state "$path")

    if [ "$desired" = "absent" ]; then
        if [ "$live" = "absent" ]; then
            echo "SATISFIED"
        else
            echo "DRIFTED"
        fi
        return 0
    fi

    if [ "$live" = "absent" ]; then
        echo "MISSING"
        return 0
    fi

    if [ -n "$target" ]; then
        local current_target
        current_target=$(readlink "$path" 2>/dev/null || true)
        if [ "$current_target" = "$target" ]; then
            echo "SATISFIED"
        else
            echo "DRIFTED"
        fi
    else
        echo "SATISFIED"
    fi
}

# Apply desired state to target symlink
# Extra fields: target
resource_symlink_apply() {
    local path="$1"
    local desired="${2:-present}"
    local comp_id="${3:-}"
    local target="${4:-}"

    if [ "$desired" = "absent" ]; then
        if [ -L "$path" ]; then
            log_info "Removing symlink '$path'..."
            rm -f "$path" 2>/dev/null || sudo rm -f "$path"
            record_transaction_item "symlink" "$path" "removed" "$comp_id"
        fi
        return 0
    fi

    log_info "Creating symlink '$path' → '$target'..."
    if create_symlink "$target" "$path"; then
        record_transaction_item "symlink" "$path" "created" "$comp_id"
        return 0
    fi
    return 1
}
