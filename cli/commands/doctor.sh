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

source "$PROJECT_ROOT/core/platform/os.sh"

run_doctor() {
    local full_check=false
    if [ "${1:-}" = "--full" ]; then
        full_check=true
    fi

    if [ "$full_check" = "true" ]; then
        echo
        echo "==========================================="
        echo " NCP Environment Self-Check (--full)"
        echo "==========================================="
        echo

        local has_errors=0

        # 1. OS check
        local os_pretty
        os_pretty=$(get_os_name)
        echo "  ✓ $os_pretty"

        # 2. Bash check
        echo "  ✓ Bash ${BASH_VERSION}"

        # 3. Package Manager
        if command -v apt-get >/dev/null 2>&1; then
            echo "  ✓ apt detected"
        elif command -v brew >/dev/null 2>&1; then
            echo "  ✓ Homebrew detected"
        else
            echo "  ! No supported package manager detected (apt/brew)"
            has_errors=1
        fi

        # 4. Init system
        local init_sys
        init_sys=$(get_init_system)
        if [ "$init_sys" != "unknown" ]; then
            echo "  ✓ $init_sys detected"
        else
            echo "  ! No supported init system detected (systemd/launchd)"
        fi

        # 5. Workspace permissions
        if [ -w "$PROJECT_ROOT" ]; then
            echo "  ✓ Workspace writable"
        else
            echo "  ! Workspace is not writable"
            has_errors=1
        fi

        # 6. State store
        local state_dir="${NCP_STATE_STORE_DIR:-${PROJECT_ROOT}/workspace/state}"
        mkdir -p "$state_dir"
        if [ -w "$state_dir" ]; then
            echo "  ✓ State store OK"
        else
            echo "  ! State store not writable"
            has_errors=1
        fi

        # 7. Session store
        local session_dir="${NCP_SESSIONS_DIR:-${PROJECT_ROOT}/workspace/sessions}"
        mkdir -p "$session_dir"
        if [ -w "$session_dir" ]; then
            echo "  ✓ Session store OK"
        else
            echo "  ! Session store not writable"
            has_errors=1
        fi

        # 8. Required Commands
        local req_cmds=("git" "curl")
        local cmd
        local missing_cmds=()
        for cmd in "${req_cmds[@]}"; do
            if ! command -v "$cmd" >/dev/null 2>&1; then
                missing_cmds+=("$cmd")
            fi
        done
        if [ ${#missing_cmds[@]} -eq 0 ]; then
            echo "  ✓ Required tools present (git, curl)"
        else
            echo "  ! Missing required tools: ${missing_cmds[*]}"
            has_errors=1
        fi

        # 9. Providers and Templates loaded
        local provider_count
        provider_count=$(discover_providers | wc -l)
        local template_count
        template_count=$(discover_templates | wc -l)
        if [ "$provider_count" -gt 0 ]; then
            echo "  ✓ Providers loaded ($provider_count)"
        else
            echo "  ! No providers found"
        fi

        # 10. Modules discovery
        local modules
        modules=$(discover_modules)
        local registered_count=0
        local module_path
        while IFS= read -r module_path; do
            [ -z "$module_path" ] && continue
            if register_component "$module_path" >/dev/null 2>&1; then
                registered_count=$((registered_count + 1))
            fi
        done <<< "$modules"

        if [ "$registered_count" -gt 0 ]; then
            echo "  ✓ Modules discovered ($registered_count)"
        else
            echo "  ! No valid modules discovered"
            has_errors=1
        fi

        echo
        if [ "$has_errors" -eq 0 ]; then
            success "Environment Ready"
            exit 0
        else
            error "Environment check failed with errors."
            exit 1
        fi
    fi

    # Standard discovery doctor (original behavior)
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

run_doctor "$@"