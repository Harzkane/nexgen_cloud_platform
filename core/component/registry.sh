#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Component Registry
# ============================================================

set -euo pipefail

REGISTRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REGISTRY_DIR/loader.sh"

# Registry to keep track of loaded component IDs (space-separated)
# Guard: only initialise once so re-sourcing this file doesn't wipe the registry.
NCP_REGISTRY_COMPONENTS="${NCP_REGISTRY_COMPONENTS:-}"

# Register a component from its folder path.
# Loads it into memory and tracks its ID.
# Usage: register_component <component_path>
register_component() {
    local comp_path="$1"
    
    if [ ! -d "$comp_path" ]; then
        echo "Error: Component directory not found: $comp_path" >&2
        return 1
    fi
    
    # Resolve absolute path
    local abs_path
    abs_path=$(cd "$comp_path" && pwd)

    # 1. Load component into memory
    if ! load_component "$abs_path"; then
        return 1
    fi

    # 2. Extract ID directly from the manifest to associate it in registry
    local comp_id
    comp_id=$(grep "^id:" "$abs_path/manifest.yml" | cut -d':' -f2- | xargs)
    if [ -z "$comp_id" ]; then
        comp_id=$(basename "$abs_path")
    fi

    # 3. Add to the list if not already registered
    if ! is_component_registered "$comp_id"; then
        if [ -z "$NCP_REGISTRY_COMPONENTS" ]; then
            NCP_REGISTRY_COMPONENTS="$comp_id"
        else
            NCP_REGISTRY_COMPONENTS="$NCP_REGISTRY_COMPONENTS $comp_id"
        fi
    fi

    return 0
}

# Check if a component is registered.
# Usage: is_component_registered <id>
is_component_registered() {
    local comp_id="$1"
    local id
    for id in $NCP_REGISTRY_COMPONENTS; do
        if [ "$id" = "$comp_id" ]; then
            return 0
        fi
    done
    return 1
}

# Get a space-separated list of all registered component IDs.
# Usage: get_registered_components
get_registered_components() {
    echo "$NCP_REGISTRY_COMPONENTS"
}

# Get a component property.
# Usage: get_component_property <id> <property_name>
get_component_property() {
    local comp_id="$1"
    local prop_name="$2"
    
    if ! is_component_registered "$comp_id"; then
        echo "Error: Component '$comp_id' is not registered" >&2
        return 1
    fi
    
    local var_id
    var_id=$(echo "$comp_id" | tr '-' '_')
    local var_name="NCP_COMP_${var_id}_${prop_name}"
    echo "${!var_name:-}"
}
