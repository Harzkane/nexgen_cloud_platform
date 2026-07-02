#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Provider: Directory
# ============================================================

set -euo pipefail

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PROVIDER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/filesystem.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"

# Returns present | absent
resource_directory_state() {
    local path="$1"
    if [ -d "$path" ]; then
        echo "present"
    else
        echo "absent"
    fi
}

# Returns SATISFIED | MISSING
resource_directory_diff() {
    local path="$1"
    local desired="${2:-present}"

    local live
    live=$(resource_directory_state "$path")

    if [ "$live" = "$desired" ]; then
        echo "SATISFIED"
    else
        echo "MISSING"
    fi
}

# Apply desired state to target directory
# Extra fields: owner, group, mode
resource_directory_apply() {
    local path="$1"
    local desired="${2:-present}"
    local comp_id="${3:-}"
    local owner="${4:-}"
    local group="${5:-}"
    local mode="${6:-}"

    local live
    live=$(resource_directory_state "$path")

    if [ "$live" = "$desired" ]; then
        log_info "Directory '$path' is already $desired."
        return 0
    fi

    if [ "$desired" = "present" ]; then
        log_info "Creating directory '$path'..."
        if create_directory "$path" "$owner" "$group" "$mode"; then
            record_transaction_item "directory" "$path" "created" "$comp_id"
            return 0
        fi
    elif [ "$desired" = "absent" ]; then
        log_info "Removing directory '$path'..."
        rm -rf "$path" 2>/dev/null || sudo rm -rf "$path"
        record_transaction_item "directory" "$path" "removed" "$comp_id"
        return 0
    fi
    return 1
}
