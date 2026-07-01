#!/usr/bin/env bash
# NCP Module: php — Verify Hook
# Category: runtime
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="php"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running verify (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement verify logic for php
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Verify complete."
exit 0
