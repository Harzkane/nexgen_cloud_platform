#!/usr/bin/env bash
# NexGen Cloud Platform (NCP)
# Module: nginx — Verify Hook
# ============================================================

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/platform/packages.sh"
source "$PROJECT_ROOT/core/platform/os.sh"

if is_cmd_available "nginx"; then
    if nginx -t >/dev/null 2>&1 || [ "$(get_os_name)" = "Darwin" ]; then
        exit 0
    fi
fi
exit 1
