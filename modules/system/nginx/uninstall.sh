#!/usr/bin/env bash
# NCP Module: nginx — Uninstall Hook
# Category: system
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="nginx"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for nginx
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
