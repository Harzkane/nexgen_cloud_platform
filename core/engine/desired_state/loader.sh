#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Desired-State Loader Subsystem
# ============================================================

set -euo pipefail

LOADER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$LOADER_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/component/registry.sh"

# Returns 0 if component has a resources block, 1 otherwise
has_desired_resources() {
    local comp_id="$1"
    local var_id
    var_id=$(echo "$comp_id" | tr '-' '_')
    local count_var="NCP_COMP_${var_id}_resources_count"
    [ -n "${!count_var:-}" ] && [ "${!count_var}" -gt 0 ] && return 0 || return 1
}

# Normalise manifest resources into canonical Resource Objects with stable IDs.
load_desired_resources() {
    local comp_id="$1"
    if ! has_desired_resources "$comp_id"; then
        return 0
    fi

    local var_id
    var_id=$(echo "$comp_id" | tr '-' '_')
    local count_var="NCP_COMP_${var_id}_resources_count"
    local count=${!count_var}

    local idx
    for ((idx=0; idx<count; idx++)); do
        local type_var="NCP_COMP_${var_id}_resources_${idx}_type"
        local type="${!type_var:-}"

        [ -z "$type" ] && continue

        local state_var="NCP_COMP_${var_id}_resources_${idx}_state"
        local state="${!state_var:-}"

        local id_var="NCP_COMP_${var_id}_resources_${idx}_id"
        local explicit_id="${!id_var:-}"

        # Resolve target name or path
        local name=""
        case "$type" in
            directory|file)
                local path_var="NCP_COMP_${var_id}_resources_${idx}_path"
                name="${!path_var:-}"
                ;;
            symlink)
                local link_var="NCP_COMP_${var_id}_resources_${idx}_link"
                name="${!link_var:-}"
                ;;
            *)
                local name_var="NCP_COMP_${var_id}_resources_${idx}_name"
                name="${!name_var:-}"
                ;;
        esac

        # Evolve Resource Schema — stable ID fallback (Refinement 3)
        local id="$explicit_id"
        if [ -z "$id" ]; then
            id="${name}-${type}"
        fi
        # Sanitise ID (replace slashes and dots with hyphens)
        id=$(echo "$id" | tr '/.' '--')

        case "$type" in
            package)
                [ -z "$state" ] && state="present"
                echo "${id}|package|${name}|${state}"
                ;;
            directory)
                local owner_var="NCP_COMP_${var_id}_resources_${idx}_owner"
                local owner="${!owner_var:-}"
                local group_var="NCP_COMP_${var_id}_resources_${idx}_group"
                local group="${!group_var:-}"
                local mode_var="NCP_COMP_${var_id}_resources_${idx}_mode"
                local mode="${!mode_var:-}"
                [ -z "$state" ] && state="present"
                echo "${id}|directory|${name}|${state}|${owner}|${group}|${mode}"
                ;;
            file)
                local content_var="NCP_COMP_${var_id}_resources_${idx}_content"
                local content="${!content_var:-}"
                local owner_var="NCP_COMP_${var_id}_resources_${idx}_owner"
                local owner="${!owner_var:-}"
                local group_var="NCP_COMP_${var_id}_resources_${idx}_group"
                local group="${!group_var:-}"
                local mode_var="NCP_COMP_${var_id}_resources_${idx}_mode"
                local mode="${!mode_var:-}"
                [ -z "$state" ] && state="present"
                # Escape content newlines and pipes
                local escaped_content
                escaped_content=$(echo -n "$content" | tr '\n' '\a' | tr '|' '\b')
                echo "${id}|file|${name}|${state}|${escaped_content}|${owner}|${group}|${mode}"
                ;;
            symlink)
                local target_var="NCP_COMP_${var_id}_resources_${idx}_target"
                local target="${!target_var:-}"
                [ -z "$state" ] && state="present"
                echo "${id}|symlink|${name}|${state}|${target}"
                ;;
            service)
                [ -z "$state" ] && state="running"
                echo "${id}|service|${name}|${state}"
                ;;
            user)
                local shell_var="NCP_COMP_${var_id}_resources_${idx}_shell"
                local shell="${!shell_var:-/bin/bash}"
                local home_var="NCP_COMP_${var_id}_resources_${idx}_homeDir"
                local home="${!home_var:-}"
                [ -z "$state" ] && state="present"
                echo "${id}|user|${name}|${state}|${shell}|${home}"
                ;;
            group)
                [ -z "$state" ] && state="present"
                echo "${id}|group|${name}|${state}"
                ;;
            *)
                # Custom fallback
                [ -z "$state" ] && state="present"
                echo "${id}|${type}|${name}|${state}"
                ;;
        esac
    done
}

# Helper to unescape file content
unescape_content() {
    local escaped="$1"
    echo -n "$escaped" | tr '\a' '\n' | tr '\b' '|'
}

# Cross-platform deterministic hashing (Refinement 4)
compute_hash() {
    local data="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        echo -n "$data" | sha256sum | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        echo -n "$data" | shasum -a 256 | cut -d' ' -f1
    elif command -v md5sum >/dev/null 2>&1; then
        echo -n "$data" | md5sum | cut -d' ' -f1
    elif command -v md5 >/dev/null 2>&1; then
        echo -n "$data" | md5
    else
        echo -n "$data" | cksum | cut -d' ' -f1
    fi
}

compute_desired_state_hash() {
    local comp_id="$1"
    local raw_resources
    raw_resources=$(load_desired_resources "$comp_id")
    compute_hash "$raw_resources"
}
