#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Execution Planner
# ============================================================
# Produces a deterministic, ordered Execution Plan from one or
# more requested component IDs. The plan is a newline-separated
# list of component IDs in the order they should be installed.
# The Installer consumes the plan without making any further
# dependency or validation decisions.
# ============================================================

set -euo pipefail

PLANNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PLANNER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/component/resolver.sh"

# ── Internal helpers ─────────────────────────────────────────────────────────

# Check if a value already exists in a newline-separated list
_plan_contains() {
    local list="$1"
    local value="$2"
    echo "$list" | grep -qx "$value" && return 0 || return 1
}

# ── Public API ───────────────────────────────────────────────────────────────

# Build an Execution Plan for one or more component IDs.
#
# Usage: build_plan <component_id...>
# Outputs: newline-separated list of component IDs in install order (stdout)
# Returns: 0 on success, 1 if any component is unknown or resolution fails
build_plan() {
    if [ "${#}" -eq 0 ]; then
        log_error "build_plan: at least one component ID is required."
        return 1
    fi

    local requested=("$@")
    local combined_plan=""
    local failed=0

    for comp_id in "${requested[@]}"; do
        # Validate the component exists in the registry
        if ! is_component_registered "$comp_id"; then
            log_error "Unknown component: '$comp_id'. Is it registered?"
            failed=$((failed + 1))
            continue
        fi

        # Resolve full dependency chain in topological order
        local resolution=""
        if ! resolution=$(resolve_dependencies "$comp_id" 2>&1); then
            log_error "Dependency resolution failed for '$comp_id': $resolution"
            failed=$((failed + 1))
            continue
        fi

        # Merge into combined plan, skipping any already present (deduplication)
        local dep
        while IFS= read -r dep; do
            [ -z "$dep" ] && continue
            if ! _plan_contains "$combined_plan" "$dep"; then
                if [ -z "$combined_plan" ]; then
                    combined_plan="$dep"
                else
                    combined_plan="$combined_plan
$dep"
                fi
            fi
        done <<< "$(echo "$resolution" | tr ' ' '\n')"
    done

    if [ "$failed" -gt 0 ]; then
        return 1
    fi

    echo "$combined_plan"
    return 0
}

# Print a human-readable numbered plan to stdout (for dry-run / confirmation).
#
# Usage: print_plan <plan_string>
print_plan() {
    local plan="$1"

    if [ -z "$plan" ]; then
        log_warning "Execution plan is empty — nothing to do."
        return 0
    fi

    log_section "Execution Plan"

    local index=1
    local comp_id
    while IFS= read -r comp_id; do
        [ -z "$comp_id" ] && continue
        local display_name=""
        local version=""
        display_name=$(get_component_property "$comp_id" "displayName" 2>/dev/null || echo "$comp_id")
        version=$(get_component_property "$comp_id" "version" 2>/dev/null || echo "?")
        printf "  %2d.  %-30s  v%s\n" "$index" "$display_name" "$version"
        index=$((index + 1))
    done <<< "$plan"

    echo ""
    printf "  %d component(s) will be installed.\n\n" "$((index - 1))"
}

# Return the ordered component list from a plan (one per line).
# This is what the Installer iterates.
#
# Usage: get_plan_components <plan_string>
get_plan_components() {
    echo "$1"
}
