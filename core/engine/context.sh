#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Execution Context Builder
# ============================================================

set -euo pipefail

CONTEXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CONTEXT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/validator/environment.sh"

# Initialise and export the NCP execution context for a given component.
# Usage: init_context <component_id>
init_context() {
    local comp_id="$1"

    if ! is_component_registered "$comp_id"; then
        echo "Error: Cannot init context — component '$comp_id' is not registered." >&2
        return 1
    fi

    # ── Core workspace paths ──────────────────────────────────
    export NCP_WORKSPACE="$PROJECT_ROOT/workspace"
    export NCP_LOG_DIR="$NCP_WORKSPACE/logs"
    export NCP_TEMP_DIR="$NCP_WORKSPACE/temp"
    export NCP_CONFIG_DIR="$NCP_WORKSPACE/config"

    # ── Component identity ────────────────────────────────────
    export NCP_COMPONENT_ID="$comp_id"
    export NCP_COMPONENT_VERSION
    NCP_COMPONENT_VERSION=$(get_component_property "$comp_id" "version")
    export NCP_COMPONENT_DISPLAY_NAME
    NCP_COMPONENT_DISPLAY_NAME=$(get_component_property "$comp_id" "displayName")
    export NCP_COMPONENT_CATEGORY
    NCP_COMPONENT_CATEGORY=$(get_component_property "$comp_id" "category")
    export NCP_COMPONENT_PATH
    NCP_COMPONENT_PATH=$(get_component_property "$comp_id" "componentPath")
    export NCP_COMPONENT_MANIFEST
    NCP_COMPONENT_MANIFEST=$(get_component_property "$comp_id" "manifestPath")

    # ── Runtime environment ───────────────────────────────────
    export NCP_OS
    NCP_OS=$(get_os_name)
    export NCP_ARCH
    NCP_ARCH=$(get_architecture)

    # ── Ensure workspace directories exist ────────────────────
    mkdir -p "$NCP_LOG_DIR" "$NCP_TEMP_DIR" "$NCP_CONFIG_DIR"

    return 0
}

# Clear all NCP context variables from the current shell.
clear_context() {
    unset NCP_WORKSPACE NCP_LOG_DIR NCP_TEMP_DIR NCP_CONFIG_DIR
    unset NCP_COMPONENT_ID NCP_COMPONENT_VERSION NCP_COMPONENT_DISPLAY_NAME
    unset NCP_COMPONENT_CATEGORY NCP_COMPONENT_PATH NCP_COMPONENT_MANIFEST
    unset NCP_OS NCP_ARCH
}
