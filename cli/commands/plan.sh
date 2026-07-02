#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP) CLI — Plan Command
# ============================================================

set -euo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CMD_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/discovery/modules.sh"
source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/engine/planner.sh"
source "$PROJECT_ROOT/core/engine/resource_planner.sh"

main() {
    if [ "${#}" -eq 0 ]; then
        echo "Usage: ncp plan <component_id> [component_id ...]" >&2
        exit 1
    fi

    # 1. Discover and register all modules
    local modules
    modules=$(discover_modules)
    local module_path
    while IFS= read -r module_path; do
        [ -z "$module_path" ] && continue
        local mf="$module_path/manifest.yml"
        [ -f "$mf" ] || continue
        register_component "$module_path" >/dev/null 2>&1 || true
    done <<< "$modules"

    # 2. Build execution plan
    local plan=""
    if ! plan=$(build_plan "$@" 2>&1); then
        log_error "$plan"
        exit 1
    fi

    # 3. Print plan
    print_plan "$plan"
    print_resource_plan "$plan"
}

main "$@"
