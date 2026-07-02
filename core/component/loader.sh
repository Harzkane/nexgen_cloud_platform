#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Component Loader
# ============================================================

set -euo pipefail

COMPONENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$COMPONENT_DIR/../manifest/loader.sh"

# Load a component directory into the component model.
# Usage: load_component <component_path>
load_component() {
    local comp_path="$1"
    
    if [ ! -d "$comp_path" ]; then
        echo "Error: Component directory not found: $comp_path" >&2
        return 1
    fi

    local manifest_file="$comp_path/manifest.yml"
    if [ ! -f "$manifest_file" ]; then
        echo "Error: Component manifest not found at $manifest_file" >&2
        return 1
    fi

    # Parse and validate the manifest into a temporary prefix
    local temp_prefix="NCP_TEMP_LOAD_"
    clear_manifest_variables "$temp_prefix"

    if ! load_manifest "$manifest_file" "$temp_prefix"; then
        echo "Error: Failed to load manifest for component at $comp_path" >&2
        clear_manifest_variables "$temp_prefix"
        return 1
    fi

    # Extract ID to build the component variable names
    local comp_id="${NCP_TEMP_LOAD_id}"
    local var_id
    var_id=$(echo "$comp_id" | tr '-' '_')
    
    # Store manifest path and component path
    eval "NCP_COMP_${var_id}_manifestPath=\"\$manifest_file\""
    eval "NCP_COMP_${var_id}_componentPath=\"\$comp_path\""

    # Map fields from manifest to component object variables
    local var
    for var in $(set | grep -o "^${temp_prefix}[a-zA-Z0-9_]*" | sort -u); do
        local suffix="${var#$temp_prefix}"
        local comp_var_name="NCP_COMP_${var_id}_${suffix}"
        eval "$comp_var_name=\"\$$var\""
    done

    # Clean up temporary variables
    clear_manifest_variables "$temp_prefix"
    return 0
}
