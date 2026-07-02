#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Declarative Resource API
# ============================================================

set -euo pipefail

RESOURCES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$RESOURCES_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/packages.sh"
source "$PROJECT_ROOT/core/platform/services.sh"
source "$PROJECT_ROOT/core/platform/filesystem.sh"
source "$PROJECT_ROOT/core/platform/users.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"

ensure_package() {
    local name="$1"
    if is_cmd_available "$name"; then
        log_info "Resource 'package:$name' already exists."
        return 0
    fi
    if install_package "$name"; then
        record_transaction_item "package" "$name" "installed"
        return 0
    fi
    return 1
}

ensure_directory() {
    local path="$1"
    local owner="${2:-}"
    local group="${3:-}"
    local mode="${4:-}"

    if [ -d "$path" ]; then
        log_info "Resource 'directory:$path' already exists."
        return 0
    fi
    if create_directory "$path" "$owner" "$group" "$mode"; then
        record_transaction_item "directory" "$path" "created"
        return 0
    fi
    return 1
}

ensure_file() {
    local path="$1"
    local content="${2:-}"
    local owner="${3:-}"
    local group="${4:-}"
    local mode="${5:-}"

    if [ -f "$path" ]; then
        local current_content
        current_content=$(sudo cat "$path" 2>/dev/null || echo "")
        if [ "$current_content" = "$content" ]; then
            log_info "Resource 'file:$path' already matches desired content."
            return 0
        fi
    fi
    if create_file "$path" "$content" "$owner" "$group" "$mode"; then
        record_transaction_item "file" "$path" "created"
        return 0
    fi
    return 1
}

ensure_symlink() {
    local target="$1"
    local link_path="$2"

    if [ -L "$link_path" ]; then
        local current_target
        current_target=$(readlink "$link_path" || echo "")
        if [ "$current_target" = "$target" ]; then
            log_info "Resource 'symlink:$link_path' matches desired target."
            return 0
        fi
    fi
    if create_symlink "$target" "$link_path"; then
        record_transaction_item "symlink" "$link_path" "created"
        return 0
    fi
    return 1
}

ensure_service_running() {
    local name="$1"
    if is_service_running "$name"; then
        log_info "Resource 'service:$name' is already running."
        return 0
    fi
    if start_service "$name"; then
        record_transaction_item "service" "$name" "started"
        return 0
    fi
    return 1
}

ensure_service_enabled() {
    local name="$1"
    enable_service "$name"
}

ensure_user() {
    local username="$1"
    local shell="${2:-/bin/bash}"
    local home_dir="${3:-}"

    if is_user_exists "$username"; then
        log_info "Resource 'user:$username' already exists."
        return 0
    fi
    if create_user "$username" "$shell" "$home_dir"; then
        record_transaction_item "user" "$username" "created"
        return 0
    fi
    return 1
}

ensure_group() {
    local groupname="$1"

    if is_group_exists "$groupname"; then
        log_info "Resource 'group:$groupname' already exists."
        return 0
    fi
    if create_group "$groupname"; then
        record_transaction_item "group" "$groupname" "created"
        return 0
    fi
    return 1
}

# --- Resource Inspection APIs ---

resource_state() {
    local type="$1"
    local target="$2"

    case "$type" in
        package)
            is_cmd_available "$target" && echo "INSTALLED" || echo "NOT_FOUND"
            ;;
        directory)
            [ -d "$target" ] && echo "EXISTS" || echo "NOT_FOUND"
            ;;
        file)
            [ -f "$target" ] && echo "EXISTS" || echo "NOT_FOUND"
            ;;
        symlink)
            [ -L "$target" ] && readlink "$target" || echo "NOT_FOUND"
            ;;
        service)
            is_service_running "$target" && echo "RUNNING" || echo "STOPPED"
            ;;
        user)
            is_user_exists "$target" && echo "EXISTS" || echo "NOT_FOUND"
            ;;
        group)
            is_group_exists "$target" && echo "EXISTS" || echo "NOT_FOUND"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

resource_diff() {
    local type="$1"
    local target="$2"
    local desired="${3:-}"

    case "$type" in
        package)
            is_cmd_available "$target" && return 0 || return 1
            ;;
        directory)
            [ -d "$target" ] && return 0 || return 1
            ;;
        file)
            if [ -f "$target" ]; then
                [ -z "$desired" ] && return 0
                local current
                current=$(sudo cat "$target" 2>/dev/null || echo "")
                [ "$current" = "$desired" ] && return 0 || return 1
            fi
            return 1
            ;;
        symlink)
            if [ -L "$target" ]; then
                local current_target
                current_target=$(readlink "$target" || echo "")
                [ "$current_target" = "$desired" ] && return 0 || return 1
            fi
            return 1
            ;;
        service)
            if [ "$desired" = "running" ]; then
                is_service_running "$target" && return 0 || return 1
            else
                is_service_running "$target" && return 1 || return 0
            fi
            ;;
        user)
            is_user_exists "$target" && return 0 || return 1
            ;;
        group)
            is_group_exists "$target" && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# ---------------------------------------------------------------------------
# check_resource_state <type> <target> [desired]
#
# Single-source-of-truth for drift detection.
# Returns: 0 if the resource exists and matches desired state (SATISFIED)
#          1 if the resource is missing or does not match (UNSATISFIED)
#
# The Reconciler calls this instead of running status hooks, ensuring
# resource logic lives in exactly one place.
# ---------------------------------------------------------------------------
check_resource_state() {
    local type="$1"
    local target="$2"
    local desired="${3:-}"

    case "$type" in
        package)
            if is_cmd_available "$target"; then
                log_info "check_resource_state: package '$target' → SATISFIED"
                return 0
            fi
            log_info "check_resource_state: package '$target' → UNSATISFIED (not found)"
            return 1
            ;;
        directory)
            if [ -d "$target" ]; then
                log_info "check_resource_state: directory '$target' → SATISFIED"
                return 0
            fi
            log_info "check_resource_state: directory '$target' → UNSATISFIED (missing)"
            return 1
            ;;
        file)
            if [ -f "$target" ]; then
                if [ -z "$desired" ]; then
                    log_info "check_resource_state: file '$target' → SATISFIED (exists)"
                    return 0
                fi
                local current
                current=$(cat "$target" 2>/dev/null || echo "")
                if [ "$current" = "$desired" ]; then
                    log_info "check_resource_state: file '$target' → SATISFIED (content matches)"
                    return 0
                fi
                log_info "check_resource_state: file '$target' → UNSATISFIED (content mismatch)"
                return 1
            fi
            log_info "check_resource_state: file '$target' → UNSATISFIED (missing)"
            return 1
            ;;
        symlink)
            if [ -L "$target" ]; then
                local current_target
                current_target=$(readlink "$target" || echo "")
                if [ -z "$desired" ] || [ "$current_target" = "$desired" ]; then
                    log_info "check_resource_state: symlink '$target' → SATISFIED"
                    return 0
                fi
                log_info "check_resource_state: symlink '$target' → UNSATISFIED (points to '$current_target', want '$desired')"
                return 1
            fi
            log_info "check_resource_state: symlink '$target' → UNSATISFIED (missing)"
            return 1
            ;;
        service)
            if is_service_running "$target"; then
                if [ -z "$desired" ] || [ "$desired" = "running" ]; then
                    log_info "check_resource_state: service '$target' → SATISFIED (running)"
                    return 0
                fi
                log_info "check_resource_state: service '$target' → UNSATISFIED (running but desired='$desired')"
                return 1
            fi
            if [ "$desired" = "stopped" ]; then
                log_info "check_resource_state: service '$target' → SATISFIED (stopped)"
                return 0
            fi
            log_info "check_resource_state: service '$target' → UNSATISFIED (not running)"
            return 1
            ;;
        user)
            if is_user_exists "$target"; then
                log_info "check_resource_state: user '$target' → SATISFIED"
                return 0
            fi
            log_info "check_resource_state: user '$target' → UNSATISFIED (missing)"
            return 1
            ;;
        group)
            if is_group_exists "$target"; then
                log_info "check_resource_state: group '$target' → SATISFIED"
                return 0
            fi
            log_info "check_resource_state: group '$target' → UNSATISFIED (missing)"
            return 1
            ;;
        *)
            log_warning "check_resource_state: unknown type '$type'"
            return 1
            ;;
    esac
}
