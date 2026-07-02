#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Planner Engine
# ============================================================
# Expands a component-level plan into a detailed resource-level
# execution plan showing ADD/SKIP/UPDATE/START actions.
# ============================================================

set -euo pipefail

PLANNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PLANNER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/engine/desired_state/loader.sh"
source "$PROJECT_ROOT/core/engine/dispatcher.sh"

# Expand a component ID into its resource-level actions.
# Format: action|type|name|desired_state|id
expand_component_resources() {
    local comp_id="$1"
    if ! has_desired_resources "$comp_id"; then
        return 0
    fi

    local res_line
    while IFS= read -r res_line; do
        [ -z "$res_line" ] && continue

        # Format: id|type|name|desired_state|extra...
        local id type name desired
        id=$(echo "$res_line" | cut -d'|' -f1)
        type=$(echo "$res_line" | cut -d'|' -f2)
        name=$(echo "$res_line" | cut -d'|' -f3)
        desired=$(echo "$res_line" | cut -d'|' -f4)

        # Parse extra arguments if any
        local extra
        extra=$(echo "$res_line" | cut -d'|' -f5- || echo "")

        # Call dispatcher to get diff
        local diff_status="MISSING"
        # We replace escaped content/newlines in extra for diff checking if needed
        local unescaped_extra=""
        if [ "$type" = "file" ]; then
            local escaped_content
            escaped_content=$(echo "$extra" | cut -d'|' -f1)
            local content
            content=$(unescape_content "$escaped_content")
            local owner group mode
            owner=$(echo "$extra" | cut -d'|' -f2)
            group=$(echo "$extra" | cut -d'|' -f3)
            mode=$(echo "$extra" | cut -d'|' -f4)
            diff_status=$(resource_dispatch "$type" diff "$name" "$desired" "$content" || echo "MISSING")
        elif [ "$type" = "symlink" ]; then
            local target
            target=$(echo "$extra" | cut -d'|' -f1)
            diff_status=$(resource_dispatch "$type" diff "$name" "$desired" "$target" || echo "MISSING")
        else
            diff_status=$(resource_dispatch "$type" diff "$name" "$desired" || echo "MISSING")
        fi

        local action="CREATE"
        case "$diff_status" in
            SATISFIED)
                action="NOOP"
                ;;
            MISSING)
                if [ "$type" = "service" ]; then
                    [ "$desired" = "running" ] && action="START" || action="NOOP"
                elif [ "$desired" = "absent" ]; then
                    action="NOOP"
                else
                    action="CREATE"
                fi
                ;;
            DRIFTED)
                if [ "$type" = "service" ]; then
                    [ "$desired" = "running" ] && action="START" || action="STOP"
                elif [ "$desired" = "absent" ]; then
                    action="DELETE"
                else
                    action="UPDATE"
                fi
                ;;
        esac

        echo "${action}|${type}|${name}|${desired}|${id}"
    done < <(load_desired_resources "$comp_id")
}

# Build and display the resource plan for all components in the plan
print_resource_plan() {
    local plan="$1"
    local comps
    comps=$(get_plan_components "$plan" 2>/dev/null || echo "$plan")

    local comp_id
    while IFS= read -r comp_id; do
        [ -z "$comp_id" ] && continue

        if has_desired_resources "$comp_id"; then
            echo "  Component: $comp_id"
            echo "  Resources:"
            local res_action_line
            while IFS= read -r res_action_line; do
                [ -z "$res_action_line" ] && continue
                local action type name desired id
                action=$(echo "$res_action_line" | cut -d'|' -f1)
                type=$(echo "$res_action_line" | cut -d'|' -f2)
                name=$(echo "$res_action_line" | cut -d'|' -f3)
                desired=$(echo "$res_action_line" | cut -d'|' -f4)
                id=$(echo "$res_action_line" | cut -d'|' -f5)

                echo "    $(printf '%-6s' "$action") ${type}:${name} [id: ${id}] (${desired})"
            done < <(expand_component_resources "$comp_id")
            echo ""
        fi
    done <<< "$comps"
}
