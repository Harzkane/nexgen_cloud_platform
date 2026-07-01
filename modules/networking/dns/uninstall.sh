#!/usr/bin/env bash
# NCP Module: dns — Uninstall Hook
# Category: networking
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="dns"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for dns
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
