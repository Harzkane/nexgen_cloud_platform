#!/usr/bin/env bash
# NexGen Cloud Platform (NCP)
# Module: build-tools — Status Hook
# ============================================================

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/state/state.sh"
source "$PROJECT_ROOT/core/platform/packages.sh"

if is_installed "build-tools"; then
    exit 0
fi

if is_cmd_available "make"; then
    mark_installed "build-tools" "0.1.0"
    exit 0
fi

exit 1
