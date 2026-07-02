#!/usr/bin/env bash
# NexGen Cloud Platform (NCP)
# Module: docker — Verify Hook
# ============================================================

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/platform/packages.sh"

if is_cmd_available "docker"; then
    exit 0
else
    exit 1
fi
