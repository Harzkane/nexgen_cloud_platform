#!/usr/bin/env bash
# NCP Module: uptime — Uninstall Hook
# Category: monitoring
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="uptime"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for uptime
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
