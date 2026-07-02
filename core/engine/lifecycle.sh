#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Lifecycle Engine
# ============================================================

set -euo pipefail

LIFECYCLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$LIFECYCLE_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/engine/context.sh"
source "$PROJECT_ROOT/core/engine/executor.sh"

# Execute a named lifecycle hook for a registered component.
#
# Usage: execute_lifecycle_hook <component_id> <hook_name>
#   hook_name: install | verify | status | configure | upgrade | uninstall
#
# Returns:
#   0 — hook executed and succeeded
#   1 — hook is missing (no script defined in manifest)
#   N — exit code of the script
execute_lifecycle_hook() {
    local comp_id="$1"
    local hook_name="$2"

    # Validate the component is registered
    if ! is_component_registered "$comp_id"; then
        log_error "Component '$comp_id' is not registered in the registry."
        return 1
    fi

    # Initialise execution context
    if ! init_context "$comp_id"; then
        log_error "Failed to initialise execution context for '$comp_id'."
        return 1
    fi

    # Resolve the lifecycle script from the component's manifest
    local var_id
    var_id=$(echo "$comp_id" | tr '-' '_')
    local script_var="NCP_COMP_${var_id}_lifecycle_${hook_name}_script"
    local script_name="${!script_var:-}"

    if [ -z "$script_name" ]; then
        log_warning "No '$hook_name' hook defined for component '$comp_id'. Skipping."
        clear_context
        return 0
    fi

    local comp_path="${NCP_COMPONENT_PATH}"
    local script_path="$comp_path/$script_name"

    if [ ! -f "$script_path" ]; then
        log_error "Lifecycle script not found: $script_path"
        clear_context
        return 1
    fi

    # Resolve timeout and sudo settings from the manifest
    local timeout_var="NCP_COMP_${var_id}_lifecycle_${hook_name}_timeout"
    local sudo_var="NCP_COMP_${var_id}_lifecycle_${hook_name}_requiresSudo"
    local timeout="${!timeout_var:-300}"
    local requires_sudo="${!sudo_var:-false}"

    # Determine log file path
    local log_file="${NCP_LOG_DIR}/${comp_id}_${hook_name}.log"

    log_step "$hook_name" "Running '$hook_name' for ${NCP_COMPONENT_DISPLAY_NAME} v${NCP_COMPONENT_VERSION}"

    local start_ts end_ts duration
    start_ts=$(date +%s)

    local exit_code=0
    execute_script "$script_path" "$timeout" "$requires_sudo" "$log_file" || exit_code=$?

    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))

    log_lifecycle_result "$comp_id" "$hook_name" "$exit_code" "$duration" "$log_file"

    clear_context
    return "$exit_code"
}
