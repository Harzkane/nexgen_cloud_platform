#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP) CLI — Verify Command
# ============================================================

set -euo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CMD_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/discovery/modules.sh"
source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/engine/lifecycle.sh"

main() {
    if [ "${#}" -eq 0 ]; then
        echo "Usage: ncp verify <component_id>" >&2
        exit 1
    fi

    local target="$1"

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

    if ! execute_lifecycle_hook "$target" "verify"; then
        log_error "Verification check for '$target' failed."
        exit 1
    fi
}

main "$@"
