#!/usr/bin/env bash
# NexGen Cloud Platform (NCP)
# Module: git — Verify Hook
# ============================================================

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/platform/packages.sh"

if is_cmd_available "git" && git --version >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi
