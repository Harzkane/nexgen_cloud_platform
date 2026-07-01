#!/usr/bin/env bash
# NCP Module: python — Upgrade Hook
# Category: runtime
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="python"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running upgrade (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement upgrade logic for python
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Upgrade complete."
exit 0
