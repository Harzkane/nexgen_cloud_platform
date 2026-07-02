#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Dispatcher
# ============================================================
# Routes resource actions dynamically to the correct provider:
#   core/resources/<type>.sh
#
# API Actions:
#   resource_dispatch <type> state   <target> [args...]
#   resource_dispatch <type> diff    <target> <desired> [args...]
#   resource_dispatch <type> apply   <target> <desired> <comp_id> [args...]
# ============================================================

set -euo pipefail

DISPATCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DISPATCHER_DIR/../.." && pwd)"

# Dynamic dispatch function
resource_dispatch() {
    local type="$1"
    local action="$2"
    local target="$3"
    shift 3
    # Remaining args go to the specific provider function

    local provider_file="${PROJECT_ROOT}/core/resources/${type}.sh"
    if [ ! -f "$provider_file" ]; then
        echo "Error: Unknown resource type provider: $type (expected at $provider_file)" >&2
        return 1
    fi

    # Source the provider file dynamically
    # shellcheck disable=SC1090
    source "$provider_file"

    local func_name="resource_${type}_${action}"
    if ! declare -f "$func_name" >/dev/null 2>&1; then
        echo "Error: Action '$action' not implemented for resource provider '$type'" >&2
        return 1
    fi

    # Invoke action function passing remaining arguments
    "$func_name" "$target" "$@"
}
