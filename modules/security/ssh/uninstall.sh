#!/usr/bin/env bash
# NCP Module: ssh — Uninstall Hook
# Category: security
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="ssh"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running uninstall (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement uninstall logic for ssh
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Uninstall complete."
exit 0
