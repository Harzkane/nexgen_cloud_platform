#!/usr/bin/env bash
# NCP Module: firewall — Uninstall Hook
# Category: security
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="firewall"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for firewall
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
