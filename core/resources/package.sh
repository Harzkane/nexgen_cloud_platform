#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Provider: Package
# ============================================================

set -euo pipefail

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PROVIDER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/packages.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"

# Get live status of package resource
# Returns present | absent
resource_package_state() {
    local name="$1"
    if is_cmd_available "$name"; then
        echo "present"
    else
        echo "absent"
    fi
}

# Diff live status against desired state
# Returns SATISFIED | MISSING
resource_package_diff() {
    local name="$1"
    local desired="${2:-present}"
    
    local live
    live=$(resource_package_state "$name")

    if [ "$live" = "$desired" ]; then
        echo "SATISFIED"
    else
        echo "MISSING"
    fi
}

# Apply desired state to target package
resource_package_apply() {
    local name="$1"
    local desired="${2:-present}"
    local comp_id="${3:-}"

    local live
    live=$(resource_package_state "$name")

    if [ "$live" = "$desired" ]; then
        log_info "Package '$name' is already $desired."
        return 0
    fi

    if [ "$desired" = "present" ]; then
        log_info "Installing package '$name'..."
        if install_package "$name"; then
            record_transaction_item "package" "$name" "installed" "$comp_id"
            return 0
        fi
    elif [ "$desired" = "absent" ]; then
        log_info "Uninstalling package '$name'..."
        if uninstall_package "$name"; then
            record_transaction_item "package" "$name" "uninstalled" "$comp_id"
            return 0
        fi
    fi
    return 1
}
