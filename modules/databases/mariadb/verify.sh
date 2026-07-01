#!/usr/bin/env bash
# NCP Module: mariadb — Verify Hook
# Category: databases
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="mariadb"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running verify (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement verify logic for mariadb
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Verify complete."
exit 0
