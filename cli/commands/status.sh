#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP) CLI — Status Command
# ============================================================

set -euo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CMD_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/engine/operations.sh"
source "$PROJECT_ROOT/core/engine/lifecycle.sh"

main() {
    if [ "${#}" -eq 0 ]; then
        echo "Usage: ncp status [--check-drift] <component_id>" >&2
        exit 1
    fi

    local check_drift=false
    local target=""

    for arg in "$@"; do
        if [ "$arg" = "--check-drift" ]; then
            check_drift=true
        else
            target="$arg"
        fi
    done

    if [ -z "$target" ]; then
        echo "Usage: ncp status [--check-drift] <component_id>" >&2
        exit 1
    fi

    # Discover and register modules
    local modules
    modules=$(discover_modules)
    local module_path
    while IFS= read -r module_path; do
        [ -z "$module_path" ] && continue
        local mf="$module_path/manifest.yml"
        [ -f "$mf" ] || continue
        register_component "$module_path" >/dev/null 2>&1 || true
    done <<< "$modules"

    if [ "$check_drift" = "true" ]; then
        if ! run_operation "reconcile" "$target"; then
            exit 2
        fi
    else
        if ! execute_lifecycle_hook "$target" "status"; then
            log_error "Status check for '$target' returned non-zero (Not Running/Not Installed)."
            exit 1
        fi
    fi
}

main "$@"
