#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Filesystem Abstraction Service
# ============================================================

set -euo pipefail

FILESYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$FILESYSTEM_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"

create_directory() {
    local path="$1"
    local owner="${2:-}"
    local group="${3:-}"
    local mode="${4:-}"

    if [ ! -d "$path" ]; then
        log_info "Creating directory: $path"
        if ! mkdir -p "$path" 2>/dev/null; then
            if ! sudo mkdir -p "$path"; then
                return 1
            fi
        fi
    fi

    if [ -n "$owner" ]; then
        local target="$owner"
        if [ -n "$group" ]; then
            target="$owner:$group"
        fi
        if ! chown "$target" "$path" 2>/dev/null; then
            if ! sudo chown "$target" "$path"; then
                return 1
            fi
        fi
    fi

    if [ -n "$mode" ]; then
        if ! chmod "$mode" "$path" 2>/dev/null; then
            if ! sudo chmod "$mode" "$path"; then
                return 1
            fi
        fi
    fi
    return 0
}

create_file() {
    local path="$1"
    local content="${2:-}"
    local owner="${3:-}"
    local group="${4:-}"
    local mode="${5:-}"

    log_info "Writing file: $path"
    if ! echo -n "$content" > "$path" 2>/dev/null; then
        if ! echo -n "$content" | sudo tee "$path" >/dev/null; then
            return 1
        fi
    fi

    if [ -n "$owner" ]; then
        local target="$owner"
        if [ -n "$group" ]; then
            target="$owner:$group"
        fi
        if ! chown "$target" "$path" 2>/dev/null; then
            if ! sudo chown "$target" "$path"; then
                return 1
            fi
        fi
    fi

    if [ -n "$mode" ]; then
        if ! chmod "$mode" "$path" 2>/dev/null; then
            if ! sudo chmod "$mode" "$path"; then
                return 1
            fi
        fi
    fi
    return 0
}

create_symlink() {
    local target="$1"
    local link_path="$2"

    if [ -L "$link_path" ] || [ -e "$link_path" ]; then
        if ! rm -f "$link_path" 2>/dev/null; then
            if ! sudo rm -f "$link_path"; then
                return 1
            fi
        fi
    fi

    log_info "Creating symlink: $link_path -> $target"
    if ! ln -s "$target" "$link_path" 2>/dev/null; then
        if ! sudo ln -s "$target" "$link_path"; then
            return 1
        fi
    fi
    return 0
}
