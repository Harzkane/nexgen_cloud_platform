#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Provider: File
# ============================================================

set -euo pipefail

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PROVIDER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/filesystem.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"

# Returns present | absent
resource_file_state() {
    local path="$1"
    if [ -f "$path" ]; then
        echo "present"
    else
        echo "absent"
    fi
}

# Returns SATISFIED | MISSING | DRIFTED
resource_file_diff() {
    local path="$1"
    local desired="${2:-present}"
    local content="${3:-}"

    local live
    live=$(resource_file_state "$path")

    if [ "$desired" = "absent" ]; then
        if [ "$live" = "absent" ]; then
            echo "SATISFIED"
        else
            echo "DRIFTED" # File exists but should be absent
        fi
        return 0
    fi

    if [ "$live" = "absent" ]; then
        echo "MISSING"
        return 0
    fi

    # Check content if specified
    if [ -n "$content" ]; then
        local live_content
        live_content=$(cat "$path" 2>/dev/null || true)
        if [ "$live_content" = "$content" ]; then
            echo "SATISFIED"
        else
            echo "DRIFTED"
        fi
    else
        echo "SATISFIED"
    fi
}

# Apply desired state to target file
# Extra fields: content, owner, group, mode
resource_file_apply() {
    local path="$1"
    local desired="${2:-present}"
    local comp_id="${3:-}"
    local content="${4:-}"
    local owner="${5:-}"
    local group="${6:-}"
    local mode="${7:-}"

    if [ "$desired" = "absent" ]; then
        if [ -f "$path" ]; then
            log_info "Removing file '$path'..."
            rm -f "$path" 2>/dev/null || sudo rm -f "$path"
            record_transaction_item "file" "$path" "removed" "$comp_id"
        fi
        return 0
    fi

    # Create/update file
    log_info "Ensuring file '$path'..."
    if create_file "$path" "$content" "$owner" "$group" "$mode"; then
        record_transaction_item "file" "$path" "created" "$comp_id"
        return 0
    fi
    return 1
}
