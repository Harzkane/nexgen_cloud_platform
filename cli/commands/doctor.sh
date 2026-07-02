#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# CLI Doctor Command Implementation
# ============================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "$PROJECT_ROOT/core/utils/output.sh"
source "$PROJECT_ROOT/core/discovery/modules.sh"
source "$PROJECT_ROOT/core/discovery/providers.sh"
source "$PROJECT_ROOT/core/discovery/templates.sh"
source "$PROJECT_ROOT/core/validator/environment.sh"
source "$PROJECT_ROOT/core/component/resolver.sh"

run_doctor() {
    echo
    echo "==========================================="
    echo " NexGen Cloud Platform"
    echo " Version: $(cat "$PROJECT_ROOT/VERSION")"
    echo "==========================================="
    echo

    info "Environment"
    echo "  OS           : $(get_os_name)"
    echo "  Kernel       : $(get_kernel)"
    echo "  Architecture : $(get_architecture)"
    echo

    # 1. Discover and Register Modules
    local modules
    modules=$(discover_modules)

    local registered_count=0
    local failed_count=0

    # Loop through and register each module
    local module_path
    while IFS= read -r module_path; do
        [ -z "$module_path" ] && continue
        # Quietly attempt registration
        if register_component "$module_path" >/dev/null 2>&1; then
            registered_count=$((registered_count + 1))
        else
            # Print warnings and let the registration function print the schema errors to stderr
            warning "Module at $module_path failed schema validation:"
            register_component "$module_path" >&2 || true
            failed_count=$((failed_count + 1))
            echo
        fi
    done <<< "$modules"

    # Get registered component IDs
    local comp_ids
    comp_ids=$(get_registered_components)

    info "Modules ($registered_count)"
    echo "-------------------------------------------"
    local comp_id
    for comp_id in $comp_ids; do
        local display_name
        display_name=$(get_component_property "$comp_id" "displayName")
        local version
        version=$(get_component_property "$comp_id" "version")
        
        printf "  ✔ %-28s v%s\n" "$display_name" "$version"
    done
    echo

    # 2. Discover Providers and Templates
    local provider_count
    provider_count=$(discover_providers | wc -l)
    local template_count
    template_count=$(discover_templates | wc -l)

    info "Infrastructure"
    echo "  Providers    : $(echo "$provider_count" | xargs)"
    echo "  Templates    : $(echo "$template_count" | xargs)"
    echo

    if [ $failed_count -gt 0 ]; then
        error "NCP Discovery completed with $failed_count validation failure(s)."
        exit 1
    else
        success "NCP Discovery completed successfully."
    fi
}

run_doctor