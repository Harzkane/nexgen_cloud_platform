#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Differ Subsystem
# ============================================================

set -euo pipefail

DIFFER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIFFER_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/engine/desired_state/loader.sh"
source "$PROJECT_ROOT/core/engine/dispatcher.sh"

diff_resource_object() {
    local res_line="$1"

    local type name desired
    type=$(echo "$res_line" | cut -d'|' -f2)
    name=$(echo "$res_line" | cut -d'|' -f3)
    desired=$(echo "$res_line" | cut -d'|' -f4)

    local extra
    extra=$(echo "$res_line" | cut -d'|' -f5- || echo "")

    local diff_status="MISSING"

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

    echo "$diff_status"
}

is_drifted() {
    local comp_id="$1"
    if ! has_desired_resources "$comp_id"; then
        return 1
    fi

    local temp_drift
    temp_drift=$(mktemp)
    echo "false" > "$temp_drift"

    while IFS= read -r res_line; do
        [ -z "$res_line" ] && continue
        local status
        status=$(diff_resource_object "$res_line")
        if [ "$status" = "MISSING" ] || [ "$status" = "DRIFTED" ]; then
            echo "true" > "$temp_drift"
            break
        fi
    done < <(load_desired_resources "$comp_id")

    local result
    result=$(cat "$temp_drift")
    rm -f "$temp_drift"

    if [ "$result" = "true" ]; then
        return 0
    else
        return 1
    fi
}

diff_resources() {
    local comp_id="$1"
    if ! has_desired_resources "$comp_id"; then
        return 0
    fi

    local res_line
    while IFS= read -r res_line; do
        [ -z "$res_line" ] && continue
        local id type name desired status
        id=$(echo "$res_line" | cut -d'|' -f1)
        type=$(echo "$res_line" | cut -d'|' -f2)
        name=$(echo "$res_line" | cut -d'|' -f3)
        desired=$(echo "$res_line" | cut -d'|' -f4)
        status=$(diff_resource_object "$res_line")

        echo "${status}|${type}|${name}|${desired}|${id}"
    done < <(load_desired_resources "$comp_id")
}
