#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Resource Applier Subsystem
# ============================================================

set -euo pipefail

APPLIER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$APPLIER_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/engine/desired_state/loader.sh"
source "$PROJECT_ROOT/core/engine/dispatcher.sh"

apply_desired_resources() {
    local comp_id="$1"
    if ! has_desired_resources "$comp_id"; then
        return 0
    fi

    log_info "Applying declarative resources for component '$comp_id'..."

    local res_line
    while IFS= read -r res_line; do
        [ -z "$res_line" ] && continue

        local type name desired
        type=$(echo "$res_line" | cut -d'|' -f2)
        name=$(echo "$res_line" | cut -d'|' -f3)
        desired=$(echo "$res_line" | cut -d'|' -f4)

        local extra
        extra=$(echo "$res_line" | cut -d'|' -f5- || echo "")

        local rc=0

        if [ "$type" = "file" ]; then
            local escaped_content
            escaped_content=$(echo "$extra" | cut -d'|' -f1)
            local content
            content=$(unescape_content "$escaped_content")
            local owner group mode
            owner=$(echo "$extra" | cut -d'|' -f2)
            group=$(echo "$extra" | cut -d'|' -f3)
            mode=$(echo "$extra" | cut -d'|' -f4)
            resource_dispatch "$type" apply "$name" "$desired" "$comp_id" "$content" "$owner" "$group" "$mode" || rc=$?
        elif [ "$type" = "directory" ]; then
            local owner group mode
            owner=$(echo "$extra" | cut -d'|' -f1)
            group=$(echo "$extra" | cut -d'|' -f2)
            mode=$(echo "$extra" | cut -d'|' -f3)
            resource_dispatch "$type" apply "$name" "$desired" "$comp_id" "$owner" "$group" "$mode" || rc=$?
        elif [ "$type" = "symlink" ]; then
            local target
            target=$(echo "$extra" | cut -d'|' -f1)
            resource_dispatch "$type" apply "$name" "$desired" "$comp_id" "$target" || rc=$?
        elif [ "$type" = "user" ]; then
            local shell home
            shell=$(echo "$extra" | cut -d'|' -f1)
            home=$(echo "$extra" | cut -d'|' -f2)
            resource_dispatch "$type" apply "$name" "$desired" "$comp_id" "$shell" "$home" || rc=$?
        else
            resource_dispatch "$type" apply "$name" "$desired" "$comp_id" || rc=$?
        fi

        if [ "$rc" -ne 0 ]; then
            log_error "Failed to apply resource '$type:$name' for component '$comp_id'."
            return 1
        fi
    done < <(load_desired_resources "$comp_id")

    log_success "Declarative resources successfully applied for '$comp_id'."
    return 0
}
