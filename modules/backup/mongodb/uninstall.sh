#!/usr/bin/env bash
# NCP Module: mongodb — Uninstall Hook
# Category: backup
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="mongodb"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for mongodb
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
