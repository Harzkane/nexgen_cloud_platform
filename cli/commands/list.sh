#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP) CLI — List Command
# ============================================================

set -euo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CMD_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/discovery/modules.sh"
source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/state/state.sh"

main() {
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

    log_section "Available NCP Modules"

    # Header
    printf "  %-15s  %-20s  %-10s  %-15s\n" "CATEGORY" "COMPONENT ID" "VERSION" "STATUS"
    printf "  %s\n" "------------------------------------------------------------------"

    # List components from registry
    local comp_id
    for comp_id in $NCP_REGISTRY_COMPONENTS; do
        local cat display_name ver status_str
        cat=$(get_component_property "$comp_id" "category")
        ver=$(get_component_property "$comp_id" "version")

        local status
        status=$(get_component_state "$comp_id" "status")
        if [ "$status" = "INSTALLED" ]; then
            status_str="✔ Installed"
        elif [ "$status" = "FAILED" ]; then
            status_str="✘ Failed"
        else
            status_str="Not Installed"
        fi

        printf "  %-15s  %-20s  %-10s  %-15s\n" "$cat" "$comp_id" "$ver" "$status_str"
    done
    echo ""
}

main "$@"
