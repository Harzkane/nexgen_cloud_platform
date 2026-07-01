#!/usr/bin/env bash
# NCP Module: mysql — Uninstall Hook
# Category: databases
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="mysql"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for mysql
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
