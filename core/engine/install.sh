#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Engine — Installation Driver
# ============================================================

set -euo pipefail

ENGINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$ENGINE_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/engine/installer.sh"

# Entrypoint: install one or more components by ID.
# Usage: bash core/engine/install.sh <component_id> [component_id ...]
main() {
    if [ "${#}" -eq 0 ]; then
        echo "Usage: install.sh <component_id> [component_id ...]" >&2
        exit 1
    fi

    for target in "$@"; do
        if ! install_component "$target"; then
            exit 1
        fi
    done
}

main "$@"
