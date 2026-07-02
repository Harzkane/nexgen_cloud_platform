#!/usr/bin/env bash
# NexGen Cloud Platform (NCP)
# Module: git — Install Hook
# ============================================================

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/platform/resources.sh"
source "$PROJECT_ROOT/core/state/state.sh"

if ensure_package "git"; then
    mark_installed "git" "0.1.0"
    exit 0
else
    mark_failed "git" "Declarative package ensure failed"
    exit 1
fi
