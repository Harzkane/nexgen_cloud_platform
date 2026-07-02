#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Dependency Resolver
# ============================================================

set -euo pipefail

RESOLVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RESOLVER_DIR/registry.sh"

# Resolve dependencies for a list of components and output them in topological (installation) order.
# Usage: resolve_dependencies <component_id_1> [component_id_2 ...]
# Returns: Space-separated list of component IDs in correct dependency order.
resolve_dependencies() {
    local -a targets=("$@")
    local -a resolved=()
    local -a visiting=()

    contains() {
        local e match="$1"
        shift
        for e; do
            [[ "$e" == "$match" ]] && return 0
        done
        return 1
    }

    visit() {
        local node="$1"
        
        # Check for circular dependencies
        if contains "$node" "${visiting[@]:-}"; then
            echo "Error: Circular dependency detected involving '$node'" >&2
            return 1
        fi

        # If already resolved, skip
        if contains "$node" "${resolved[@]:-}"; then
            return 0
        fi

        # Mark as visiting
        visiting+=("$node")

        # Get dependencies from registry
        if is_component_registered "$node"; then
            local var_id
            var_id=$(echo "$node" | tr '-' '_')
            local count_var="NCP_COMP_${var_id}_dependencies_count"
            local count="${!count_var:-0}"
            local i
            for ((i=0; i<count; i++)); do
                local dep_id_var="NCP_COMP_${var_id}_dependencies_${i}_id"
                local dep_id="${!dep_id_var}"
                if ! visit "$dep_id"; then
                    return 1
                fi
            done
        else
            echo "Warning: Dependency '$node' is not registered in the system." >&2
        fi

        # Remove from visiting
        local temp_visiting=()
        local v
        for v in "${visiting[@]}"; do
            if [ "$v" != "$node" ]; then
                temp_visiting+=("$v")
            fi
        done
        visiting=("${temp_visiting[@]:-}")
        
        # Add to resolved list
        resolved+=("$node")
    }

    local target
    for target in "${targets[@]}"; do
        if ! visit "$target"; then
            return 1
        fi
    done

    echo "${resolved[@]}"
}
