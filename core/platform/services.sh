#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Services Abstraction Service
# ============================================================

set -euo pipefail

SERVICES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SERVICES_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/os.sh"

is_service_running() {
    local name="$1"
    local init
    init=$(get_init_system)

    case "$init" in
        systemd)
            systemctl is-active --quiet "$name" && return 0 || return 1
            ;;
        launchd)
            # Simple check if process is running on macOS
            pgrep -x "$name" >/dev/null 2>&1 && return 0 || return 1
            ;;
        *)
            # Fallback process check
            pgrep -x "$name" >/dev/null 2>&1 && return 0 || return 1
            ;;
    esac
}

start_service() {
    local name="$1"
    local init
    init=$(get_init_system)

    log_info "Starting service '$name' via $init..."
    case "$init" in
        systemd)
            sudo systemctl start "$name"
            ;;
        launchd)
            # macOS launchd commands usually need load/start
            sudo launchctl start "$name" >/dev/null 2>&1 || true
            ;;
        *)
            log_warning "Cannot start service '$name' on unsupported init system."
            return 1
            ;;
    esac
}

stop_service() {
    local name="$1"
    local init
    init=$(get_init_system)

    log_info "Stopping service '$name' via $init..."
    case "$init" in
        systemd)
            sudo systemctl stop "$name"
            ;;
        launchd)
            sudo launchctl stop "$name" >/dev/null 2>&1 || true
            ;;
        *)
            log_warning "Cannot stop service '$name' on unsupported init system."
            return 1
            ;;
    esac
}

enable_service() {
    local name="$1"
    local init
    init=$(get_init_system)

    log_info "Enabling service '$name' to start on boot via $init..."
    case "$init" in
        systemd)
            sudo systemctl enable "$name"
            ;;
        launchd)
            # macOS doesn't have an exact enable/disable equivalent without plist loading
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

disable_service() {
    local name="$1"
    local init
    init=$(get_init_system)

    log_info "Disabling service '$name' via $init..."
    case "$init" in
        systemd)
            sudo systemctl disable "$name"
            ;;
        launchd)
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}
