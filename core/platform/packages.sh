#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Package Manager Abstraction Service
# ============================================================

set -euo pipefail

PACKAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$PACKAGES_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/os.sh"

_get_package_manager() {
    local os
    os=$(get_os_name)
    if [ "$os" = "Darwin" ]; then
        echo "brew"
    elif [ "$os" = "Linux" ]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "apt"
        elif command -v yum >/dev/null 2>&1; then
            echo "yum"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

update_packages() {
    local pm
    pm=$(_get_package_manager)

    log_info "Updating system package databases via $pm..."
    case "$pm" in
        brew)
            brew update >/dev/null 2>&1 || true
            ;;
        apt)
            sudo apt-get update -y >/dev/null 2>&1 || true
            ;;
        *)
            log_warning "Unsupported package manager. Skipping update."
            ;;
    esac
}

install_package() {
    local pkg="$1"
    local pm
    pm=$(_get_package_manager)

    # Translate packages for macOS/brew compatibility
    if [ "$pm" = "brew" ]; then
        if [ "$pkg" = "build-essential" ]; then
            if command -v make >/dev/null 2>&1; then
                log_info "build-essential is satisfied by macOS developer tools."
                return 0
            else
                pkg="make"
            fi
        fi
    fi

    log_info "Installing system package '$pkg' via $pm..."
    case "$pm" in
        brew)
            if brew list "$pkg" >/dev/null 2>&1; then
                log_info "Package '$pkg' is already installed via brew."
                return 0
            fi
            brew install "$pkg"
            ;;
        apt)
            if dpkg -s "$pkg" >/dev/null 2>&1; then
                log_info "Package '$pkg' is already installed via apt."
                return 0
            fi
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
            ;;
        *)
            log_error "Unsupported package manager. Please install '$pkg' manually."
            return 1
            ;;
    esac
}

uninstall_package() {
    local pkg="$1"
    local pm
    pm=$(_get_package_manager)

    log_info "Uninstalling system package '$pkg' via $pm..."
    case "$pm" in
        brew)
            brew uninstall "$pkg" >/dev/null 2>&1 || true
            ;;
        apt)
            sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y "$pkg" >/dev/null 2>&1 || true
            ;;
        *)
            ;;
    esac
}

is_cmd_available() {
    command -v "$1" >/dev/null 2>&1
}
