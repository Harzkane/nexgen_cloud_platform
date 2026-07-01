#!/usr/bin/env bash
# NCP Module: python — Configure Hook
# Category: runtime
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="python"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running configure (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement configure logic for python
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Configure complete."
exit 0
