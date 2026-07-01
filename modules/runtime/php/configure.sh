#!/usr/bin/env bash
# NCP Module: php — Configure Hook
# Category: runtime
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="php"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running configure (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement configure logic for php
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Configure complete."
exit 0
