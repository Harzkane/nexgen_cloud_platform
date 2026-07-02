#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP) CLI — Info Command
# ============================================================

set -euo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CMD_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/discovery/modules.sh"
source "$PROJECT_ROOT/core/component/registry.sh"

main() {
    if [ "${#}" -eq 0 ]; then
        echo "Usage: ncp info <component_id>" >&2
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

    if ! is_component_registered "$target"; then
        log_error "Component '$target' is not registered."
        exit 1
    fi

    local name display_name ver cat desc license maintainer path
    name=$(get_component_property "$target" "name")
    display_name=$(get_component_property "$target" "displayName")
    ver=$(get_component_property "$target" "version")
    cat=$(get_component_property "$target" "category")
    desc=$(get_component_property "$target" "description")
    license=$(get_component_property "$target" "license" 2>/dev/null || echo "MIT")
    maintainer=$(get_component_property "$target" "maintainer" 2>/dev/null || echo "Unknown")
    path=$(get_component_property "$target" "componentPath")

    log_section "Module Info: $display_name"
    echo "  ID           : $target"
    echo "  Name         : $name"
    echo "  Version      : $ver"
    echo "  Category     : $cat"
    echo "  Maintainer   : $maintainer"
    echo "  License      : $license"
    echo "  Path         : $path"
    echo "  Description  : $desc"
    echo ""
}

main "$@"
