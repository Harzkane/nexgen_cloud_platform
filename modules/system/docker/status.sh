#!/usr/bin/env bash
# NexGen Cloud Platform (NCP)
# Module: docker — Status Hook
# ============================================================

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/state/state.sh"
source "$PROJECT_ROOT/core/platform/packages.sh"

if is_installed "docker"; then
    exit 0
fi

if is_cmd_available "docker" && docker info >/dev/null 2>&1; then
    mark_installed "docker" "1.0.0"
    exit 0
fi

exit 1
