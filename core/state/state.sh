#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# State Manager Platform Service
# ============================================================

set -euo pipefail

STATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$STATE_DIR/../.." && pwd)"

# Base state directory (supports environment overrides for testing isolation)
NCP_STATE_STORE_DIR="${NCP_STATE_STORE_DIR:-${PROJECT_ROOT}/workspace/state}"

# Ensure the state store directory exists
mkdir -p "$NCP_STATE_STORE_DIR"

_get_state_file() {
    local comp_id="$1"
    echo "$NCP_STATE_STORE_DIR/${comp_id}.state"
}

# Write a key-value pair to a component's state file
# Usage: _write_state_val <comp_id> <key> <val>
_write_state_val() {
    local comp_id="$1"
    local key="$2"
    local val="$3"
    local sf
    sf=$(_get_state_file "$comp_id")

    # Read existing content, filter out the target key, and append new key=val
    local temp_sf
    temp_sf=$(mktemp)
    if [ -f "$sf" ]; then
        grep -v "^${key}=" "$sf" > "$temp_sf" || true
    fi
    echo "${key}=${val}" >> "$temp_sf"
    mv "$temp_sf" "$sf"

    # Auto-heal permissions if run under sudo/root
    if [ "$(id -u)" = "0" ]; then
        local parent_dir
        parent_dir=$(dirname "$sf")
        local owner
        if [ "$(uname -s)" = "Darwin" ]; then
            owner=$(stat -f '%u:%g' "$parent_dir")
        else
            owner=$(stat -c '%u:%g' "$parent_dir")
        fi
        chown "$owner" "$sf"
        chmod 664 "$sf"
    fi
}

# Read a state value for a component
# Usage: get_component_state <comp_id> <key>
get_component_state() {
    local comp_id="$1"
    local key="$2"
    local sf
    sf=$(_get_state_file "$comp_id")

    if [ ! -f "$sf" ]; then
        echo ""
        return
    fi

    # Retrieve value matching key=
    local val
    val=$(grep "^${key}=" "$sf" | cut -d= -f2- || echo "")
    echo "$val"
}

# Update only the status field for a component
# Usage: update_component_status <comp_id> <status>
update_component_status() {
    local comp_id="$1"
    local status="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    _write_state_val "$comp_id" "status" "$status"
    _write_state_val "$comp_id" "last_updated" "$timestamp"
}

# State transitions
mark_planned() {
    update_component_status "$1" "PLANNED"
}

mark_installing() {
    update_component_status "$1" "INSTALLING"
}

mark_installed() {
    local comp_id="$1"
    local version="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    _write_state_val "$comp_id" "status" "INSTALLED"
    _write_state_val "$comp_id" "installed_version" "$version"
    _write_state_val "$comp_id" "last_updated" "$timestamp"
    _write_state_val "$comp_id" "last_error" ""
}

mark_configuring() {
    update_component_status "$1" "CONFIGURING"
}

mark_verifying() {
    update_component_status "$1" "VERIFYING"
}

mark_drifted() {
    update_component_status "$1" "DRIFTED"
}

mark_failed() {
    local comp_id="$1"
    local err_msg="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    _write_state_val "$comp_id" "status" "FAILED"
    _write_state_val "$comp_id" "last_updated" "$timestamp"
    _write_state_val "$comp_id" "last_error" "$err_msg"
}

mark_rolling_back() {
    update_component_status "$1" "ROLLING_BACK"
}

mark_rolled_back() {
    update_component_status "$1" "ROLLED_BACK"
}

# Check if a component is installed (status INSTALLED or DRIFTED)
# Usage: is_installed <comp_id>
# Returns 0 if installed/drifted, 1 otherwise
is_installed() {
    local comp_id="$1"
    local status
    status=$(get_component_state "$comp_id" "status")
    if [ "$status" = "INSTALLED" ] || [ "$status" = "DRIFTED" ]; then
        return 0
    else
        return 1
    fi
}

# Set a custom state value for a component
# Usage: set_component_state <comp_id> <key> <val>
set_component_state() {
    _write_state_val "$1" "$2" "$3"
}

