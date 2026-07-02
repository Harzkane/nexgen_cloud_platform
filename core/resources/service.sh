#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Provider: Service
# ============================================================

set -euo pipefail

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PROVIDER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/services.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"

# Returns running | stopped | absent
resource_service_state() {
    local name="$1"
    # Note: If service management CLI is not available or service is unknown,
    # we return stopped or absent.
    if is_service_running "$name"; then
        echo "running"
    else
        echo "stopped"
    fi
}

# Returns SATISFIED | MISSING | DRIFTED
resource_service_diff() {
    local name="$1"
    local desired="${2:-running}"

    local live
    live=$(resource_service_state "$name")

    if [ "$live" = "$desired" ]; then
        echo "SATISFIED"
    else
        # For services, if it's running but should be stopped (or vice versa), it is DRIFTED
        echo "DRIFTED"
    fi
}

# Apply desired state to target service
resource_service_apply() {
    local name="$1"
    local desired="${2:-running}"
    local comp_id="${3:-}"

    local live
    live=$(resource_service_state "$name")

    if [ "$live" = "$desired" ]; then
        log_info "Service '$name' is already $desired."
        return 0
    fi

    if [ "$desired" = "running" ]; then
        log_info "Starting service '$name'..."
        if start_service "$name"; then
            record_transaction_item "service" "$name" "started" "$comp_id"
            return 0
        fi
    elif [ "$desired" = "stopped" ]; then
        log_info "Stopping service '$name'..."
        if stop_service "$name"; then
            record_transaction_item "service" "$name" "stopped" "$comp_id"
            return 0
        fi
    fi
    return 1
}
