#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Reconciler — Desired State vs Current State
# ============================================================
# The Reconciler is generic. It carries NO resource knowledge.
# Its only job:
#
#   for each component
#     ↓
#   ask the Resource API: "Are you satisfied?"
#     ↓
#   update component state
#
# Resource logic (what "satisfied" means) lives exclusively in
# resources.sh → check_resource_state.
# ============================================================

set -euo pipefail

RECONCILER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$RECONCILER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/state/state.sh"
source "$PROJECT_ROOT/core/platform/resources.sh"
source "$PROJECT_ROOT/core/engine/events.sh"
source "$PROJECT_ROOT/core/engine/desired_state/loader.sh"
source "$PROJECT_ROOT/core/engine/desired_state/differ.sh"

# ---------------------------------------------------------------------------
# reconcile_component <component_id> [resource_checks...]
#
# Reconciles a single component against its desired resource state.
# Resource checks are passed as "type:target[:desired]" strings.
# If no checks are provided, falls back to declarative checks or legacy status hook.
#
# Returns:
#   0  — HEALTHY (all resources satisfied)
#   2  — DRIFTED (one or more resources unsatisfied)
#   1  — NOT_INSTALLED / unknown state
# ---------------------------------------------------------------------------
reconcile_component() {
    local comp_id="$1"
    shift
    local -a resource_checks=("$@")

    publish_event "component:before_status" "$comp_id"
    log_info "Reconciling component '$comp_id'..."

    # If the component declares a resources block in its manifest, use it!
    if has_desired_resources "$comp_id"; then
        # Fingerprint desired hash check (Refinement 4)
        local live_hash saved_hash
        live_hash=$(compute_desired_state_hash "$comp_id")
        saved_hash=$(get_component_state "$comp_id" "desired_hash")

        if [ -n "$saved_hash" ] && [ "$live_hash" != "$saved_hash" ]; then
            log_warning "Component '$comp_id' manifest changed (hash mismatch: $saved_hash -> $live_hash). Reconciliation required."
            mark_drifted "$comp_id"
            publish_event "component:after_status" "$comp_id" "DRIFTED"
            return 2
        fi

        local rc=0
        if is_drifted "$comp_id"; then
            log_warning "Component '$comp_id' has DRIFTED — one or more resources unsatisfied."
            mark_drifted "$comp_id"
            publish_event "component:after_status" "$comp_id" "DRIFTED"
            return 2
        else
            log_success "Component '$comp_id' is HEALTHY (all declarative resources satisfied)."
            mark_installed "$comp_id" "$(get_component_property "$comp_id" "version" 2>/dev/null || echo "")"
            publish_event "component:after_status" "$comp_id" "HEALTHY"
            return 0
        fi
    fi

    # If resource checks were supplied, use the Resource API (declarative path)
    if [ "${#resource_checks[@]}" -gt 0 ]; then
        local all_satisfied=true

        for check in "${resource_checks[@]}"; do
            # Parse "type:target[:desired]"
            local res_type res_target res_desired
            res_type=$(echo "$check" | cut -d':' -f1)
            res_target=$(echo "$check" | cut -d':' -f2)
            res_desired=$(echo "$check" | cut -d':' -f3 || echo "")

            if ! check_resource_state "$res_type" "$res_target" "$res_desired" > /dev/null 2>&1; then
                all_satisfied=false
                log_warning "Resource '$res_type:$res_target' is UNSATISFIED for component '$comp_id'."
            fi
        done

        if [ "$all_satisfied" = "true" ]; then
            log_success "Component '$comp_id' is HEALTHY (all resources satisfied)."
            mark_installed "$comp_id" "$(get_component_property "$comp_id" "version" 2>/dev/null || echo "")"
            publish_event "component:after_status" "$comp_id" "HEALTHY"
            return 0
        else
            log_warning "Component '$comp_id' has DRIFTED — one or more resources unsatisfied."
            mark_drifted "$comp_id"
            publish_event "component:after_status" "$comp_id" "DRIFTED"
            return 2
        fi
    fi

    # Fallback: legacy status hook (for components that declare a status script)
    local rc=0
    if declare -f execute_lifecycle_hook > /dev/null 2>&1; then
        execute_lifecycle_hook "$comp_id" "status" > /dev/null 2>&1 || rc=$?
    else
        rc=1
    fi

    if [ "$rc" -eq 0 ]; then
        log_success "Component '$comp_id' is HEALTHY (status hook)."
        mark_installed "$comp_id" "$(get_component_property "$comp_id" "version" 2>/dev/null || echo "")"
        publish_event "component:after_status" "$comp_id" "HEALTHY"
        return 0
    elif [ "$rc" -eq 2 ]; then
        log_warning "Component '$comp_id' has DRIFTED (status hook)."
        mark_drifted "$comp_id"
        publish_event "component:after_status" "$comp_id" "DRIFTED"
        return 2
    else
        log_info "Component '$comp_id' is NOT_INSTALLED."
        publish_event "component:after_status" "$comp_id" "NOT_INSTALLED"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# reconcile_all <component_id...>
# Reconcile a list of components; return overall drift count.
# ---------------------------------------------------------------------------
reconcile_all() {
    local drift_count=0
    local comp_id

    for comp_id in "$@"; do
        local rc=0
        reconcile_component "$comp_id" || rc=$?
        [ "$rc" -eq 2 ] && drift_count=$((drift_count + 1))
    done

    return "$drift_count"
}
