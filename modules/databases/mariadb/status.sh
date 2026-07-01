#!/usr/bin/env bash
# NCP Module: mariadb — Status Hook
# Category: databases
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="mariadb"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running status (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement status logic for mariadb
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Status complete."
exit 0
