#!/usr/bin/env bash
# NCP Module: metrics — Upgrade Hook
# Category: monitoring
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="metrics"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running upgrade (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement upgrade logic for metrics
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Upgrade complete."
exit 0
