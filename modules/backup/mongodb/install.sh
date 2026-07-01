#!/usr/bin/env bash
# NCP Module: mongodb — Install Hook
# Category: backup
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="mongodb"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running install (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement install logic for mongodb
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Install complete."
exit 0
