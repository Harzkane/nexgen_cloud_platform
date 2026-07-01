#!/usr/bin/env bash
# NCP Module: build-tools — Uninstall Hook
# Category: system
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="build-tools"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for build-tools
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
