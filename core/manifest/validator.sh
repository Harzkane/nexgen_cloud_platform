#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Manifest Schema Validator Engine
# ============================================================

set -euo pipefail

# Ensure parser is loaded
VALIDATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$VALIDATOR_DIR/parser.sh"

# Validate a manifest file.
# Usage: validate_manifest <file_path>
# Returns: 0 if valid, 1 if invalid (with printed error details)
validate_manifest() {
    local yaml_file="$1"
    
    if [ ! -f "$yaml_file" ]; then
        echo "Error: Manifest file not found at $yaml_file" >&2
        return 1
    fi

    local component_dir
    component_dir=$(dirname "$yaml_file")
    local has_errors=0
    
    # Helper to print errors
    report_error() {
        echo "  [ERROR] $1" >&2
        has_errors=1
    }

    # Clear previous manifest variables first
    clear_manifest_variables "NCP_VAL_"
    
    # Parse the manifest into the NCP_VAL_ prefix
    if ! parse_manifest "$yaml_file" "NCP_VAL_"; then
        report_error "Failed to parse YAML manifest structure."
        return 1
    fi

    # 1. Required Fields Validation
    if [ -z "${NCP_VAL_apiVersion:-}" ]; then
        report_error "Missing required field: 'apiVersion'"
    fi
    if [ -z "${NCP_VAL_kind:-}" ]; then
        report_error "Missing required field: 'kind'"
    fi
    if [ -z "${NCP_VAL_id:-}" ]; then
        report_error "Missing required field: 'id'"
    fi
    if [ -z "${NCP_VAL_name:-}" ]; then
        report_error "Missing required field: 'name'"
    fi
    if [ -z "${NCP_VAL_displayName:-}" ]; then
        report_error "Missing required field: 'displayName'"
    fi
    if [ -z "${NCP_VAL_version:-}" ]; then
        report_error "Missing required field: 'version'"
    fi
    if [ -z "${NCP_VAL_category:-}" ]; then
        report_error "Missing required field: 'category'"
    fi

    # 2. Schema Value Specifications Validation
    if [ -n "${NCP_VAL_apiVersion:-}" ] && [ "$NCP_VAL_apiVersion" != "ncp.io/v1" ]; then
        report_error "Unsupported apiVersion: '$NCP_VAL_apiVersion' (expected 'ncp.io/v1')"
    fi

    if [ -n "${NCP_VAL_kind:-}" ]; then
        case "$NCP_VAL_kind" in
            Module|Provider|Template) ;;
            *) report_error "Unsupported kind: '$NCP_VAL_kind' (expected 'Module', 'Provider', or 'Template')" ;;
        esac
    fi

    # 3. Lifecycle Scripts Existence Check
    # Verify that if a hook has a script specified, it exists in the same folder
    local hook
    for hook in install verify status configure upgrade uninstall; do
        local script_var="NCP_VAL_lifecycle_${hook}_script"
        if [ -n "${!script_var:-}" ]; then
            local script_name="${!script_var}"
            if [ ! -f "$component_dir/$script_name" ]; then
                report_error "Lifecycle hook '$hook' references non-existent script: '$script_name' (expected at $component_dir/$script_name)"
            fi
        fi
    done

    # 4. Declarative Resources Validation
    local res_count_var="NCP_VAL_resources_count"
    if [ -n "${!res_count_var:-}" ] && [ "${!res_count_var}" -gt 0 ]; then
        local count=${!res_count_var}
        local idx
        for ((idx=0; idx<count; idx++)); do
            local type_var="NCP_VAL_resources_${idx}_type"
            local type="${!type_var:-}"

            if [ -z "$type" ]; then
                report_error "Resource at index $idx is missing 'type'"
                continue
            fi

            case "$type" in
                package|directory|file|symlink|service|user|group) ;;
                *)
                    # Custom resource types are supported (Refinement 2) but warned for typing errors
                    log_warning "Resource at index $idx uses custom type: '$type'"
                    ;;
            esac

            # Type-specific validation
            case "$type" in
                package|service|user|group)
                    local name_var="NCP_VAL_resources_${idx}_name"
                    if [ -z "${!name_var:-}" ]; then
                        report_error "Resource '$type' at index $idx is missing 'name'"
                    fi
                    ;;
                directory|file)
                    local path_var="NCP_VAL_resources_${idx}_path"
                    if [ -z "${!path_var:-}" ]; then
                        report_error "Resource '$type' at index $idx is missing 'path'"
                    fi
                    ;;
                symlink)
                    local link_var="NCP_VAL_resources_${idx}_link"
                    local target_var="NCP_VAL_resources_${idx}_target"
                    if [ -z "${!link_var:-}" ]; then
                        report_error "Resource 'symlink' at index $idx is missing 'link'"
                    fi
                    if [ -z "${!target_var:-}" ]; then
                        report_error "Resource 'symlink' at index $idx is missing 'target'"
                    fi
                    ;;
            esac

            # Service state validation
            if [ "$type" = "service" ]; then
                local state_var="NCP_VAL_resources_${idx}_state"
                local state="${!state_var:-}"
                if [ -n "$state" ] && [ "$state" != "running" ] && [ "$state" != "stopped" ]; then
                    report_error "Resource 'service' at index $idx has unsupported state: '$state' (expected 'running' or 'stopped')"
                fi
            fi
        done
    fi

    # Clean up validation variables
    clear_manifest_variables "NCP_VAL_"

    return $has_errors
}
