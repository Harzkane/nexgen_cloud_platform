#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Installer Engine
# ============================================================
# The Installer is a pure executor of an Execution Plan.
# All decision-making (dependency resolution, deduplication,
# validation) is owned by the Planner (planner.sh).
#
# Refinements applied:
#   - Records already_present vs installed_this_run in the
#     active transaction for precise rollback semantics.
#   - Emits the full component:* lifecycle event namespace at
#     every hook boundary.
# ============================================================

set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$INSTALLER_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/engine/planner.sh"
source "$PROJECT_ROOT/core/engine/lifecycle.sh"
source "$PROJECT_ROOT/core/engine/executor.sh"
source "$PROJECT_ROOT/core/discovery/modules.sh"
source "$PROJECT_ROOT/core/manifest/loader.sh"
source "$PROJECT_ROOT/core/state/state.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"
source "$PROJECT_ROOT/core/engine/events.sh"
source "$PROJECT_ROOT/core/engine/desired_state/loader.sh"
source "$PROJECT_ROOT/core/engine/desired_state/applier.sh"
source "$PROJECT_ROOT/core/engine/desired_state/differ.sh"

# ── Helpers ───────────────────────────────────────────────────────────────────

_requires_sudo_for() {
    local comp_id="$1"
    local var_id
    var_id=$(echo "$comp_id" | tr '-' '_')
    local sudo_var="NCP_COMP_${var_id}_lifecycle_install_requiresSudo"
    [ "${!sudo_var:-false}" = "true" ] && return 0 || return 1
}

_is_installed() {
    local comp_id="$1"

    # If component has declarative resources, check if it is drifted/missing
    if has_desired_resources "$comp_id"; then
        if is_drifted "$comp_id"; then
            return 1 # Drifted or missing -> needs install/repair
        else
            return 0 # All resources satisfied -> already installed
        fi
    fi

    local var_id
    var_id=$(echo "$comp_id" | tr '-' '_')
    local script_var="NCP_COMP_${var_id}_lifecycle_status_script"
    local script_name="${!script_var:-}"

    [ -z "$script_name" ] && return 1

    local comp_path
    comp_path=$(get_component_property "$comp_id" "componentPath")
    local script_path="$comp_path/$script_name"

    [ -f "$script_path" ] || return 1
    bash "$script_path" > /dev/null 2>&1 && return 0 || return 1
}

# ── Core Installation Function ────────────────────────────────────────────────

# Install one or more components using the Planner + Lifecycle Engine.
#
# Usage: install_plan_execution <plan>
# Returns: 0 on success, 1 on failure (enabling rollback)
install_plan_execution() {
    local plan="$1"

    # --- 1. Prompt for sudo once if anything requires it ---------------------
    local needs_sudo=false
    local id
    while IFS= read -r id; do
        [ -z "$id" ] && continue
        if _requires_sudo_for "$id"; then
            needs_sudo=true
            break
        fi
    done <<< "$plan"

    if [ "$needs_sudo" = "true" ]; then
        log_warning "Some components require elevated privileges. You may be prompted for your password."
        if ! sudo_keepalive_start; then
            log_error "Failed to acquire sudo. Aborting installation."
            return 1
        fi
    fi

    # --- 2. Execute the plan --------------------------------------------------
    while IFS= read -r id; do
        [ -z "$id" ] && continue

        local display_name version
        display_name=$(get_component_property "$id" "displayName")
        version=$(get_component_property "$id" "version")

        # Emit plan event
        publish_event "component:plan" "$id" "v${version}"
        log_section "Installing: $display_name v$version"

        # ── Already installed check ──────────────────────────────────────────
        if _is_installed "$id"; then
            log_success "$display_name is already installed. Skipping."
            mark_installed "$id" "$version"
            # Record as already-present so rollback will not touch it
            record_component_already_present "$id"
            continue
        fi

        # ── State: PLANNED → INSTALLING ──────────────────────────────────────
        mark_planned "$id"
        publish_event "component:before_install" "$id"
        mark_installing "$id"

        # ── Declarative Resource Application ──────────────────────────────────
        if has_desired_resources "$id"; then
            if ! apply_desired_resources "$id"; then
                log_error "Declarative resource application failed for '$id'."
                mark_failed "$id" "Declarative resources failed"
                publish_event "component:failure" "$id" "DECLARATIVE_APPLY_FAILED"
                sudo_keepalive_stop
                return 1
            fi
        fi

        # ── Install hook ─────────────────────────────────────────────────────
        if ! execute_lifecycle_hook "$id" "install"; then
            log_error "Installation of '$id' failed."
            mark_failed "$id" "Installation hook failed"
            publish_event "component:failure" "$id" "INSTALL_HOOK_FAILED"
            sudo_keepalive_stop
            return 1
        fi
        publish_event "component:after_install" "$id" "SUCCESS"

        # ── Verify hook ──────────────────────────────────────────────────────
        mark_verifying "$id"
        publish_event "component:before_verify" "$id"
        if ! execute_lifecycle_hook "$id" "verify"; then
            log_error "Verification of '$id' failed after installation."
            mark_failed "$id" "Verification hook failed"
            publish_event "component:failure" "$id" "VERIFY_HOOK_FAILED"
            sudo_keepalive_stop
            return 1
        fi
        publish_event "component:after_verify" "$id" "SUCCESS"

        # ── Configure hook ───────────────────────────────────────────────────
        mark_configuring "$id"
        publish_event "component:before_configure" "$id"
        execute_lifecycle_hook "$id" "configure" || true
        publish_event "component:after_configure" "$id"

        # ── Fully installed ──────────────────────────────────────────────────
        mark_installed "$id" "$version"

        # Persist desired-state hash on successful installation (Refinement 4)
        if has_desired_resources "$id"; then
            set_component_state "$id" "desired_hash" "$(compute_desired_state_hash "$id")"
        fi

        # Record as installed THIS run so rollback can undo it if needed
        record_component_installed_this_run "$id"

        publish_event "component:complete" "$id" "INSTALLED@v${version}"
        log_success "$display_name installed successfully."

    done <<< "$(get_plan_components "$plan")"

    # --- 3. Stop sudo keep-alive ----------------------------------------------
    sudo_keepalive_stop
    return 0
}

# Legacy wrapper for backward compatibility
install_component() {
    local targets=("$@")

    log_section "NCP Installer"

    # --- Ensure all modules are registered -----------------------------------
    local modules
    modules=$(discover_modules)
    local module_path
    while IFS= read -r module_path; do
        [ -z "$module_path" ] && continue
        local mf="$module_path/manifest.yml"
        [ -f "$mf" ] || continue
        register_component "$module_path" > /dev/null 2>&1 || true
    done <<< "$modules"

    log_info "Building execution plan for: ${targets[*]}"
    local plan=""
    if ! plan=$(build_plan "${targets[@]}" 2>&1); then
        log_error "$plan"
        return 1
    fi

    print_plan "$plan"

    if ! install_plan_execution "$plan"; then
        return 1
    fi

    log_success "All components installed and verified."
    return 0
}
