#!/usr/bin/env bash
# NCP Module: s3 — Uninstall Hook
# Category: backup
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="s3"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for s3
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
