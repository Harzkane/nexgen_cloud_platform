#!/usr/bin/env bash
# NexGen Cloud Platform (NCP)
# Module: nginx — Install Hook
# ============================================================

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/platform/resources.sh"
source "$PROJECT_ROOT/core/state/state.sh"

if ensure_package "nginx"; then
    mark_installed "nginx" "0.1.0"
    exit 0
else
    mark_failed "nginx" "Declarative package ensure failed"
    exit 1
fi
