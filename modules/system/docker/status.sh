#!/usr/bin/env bash
# NCP Module: docker — Status Hook
# Category: system
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="docker"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running status (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement status logic for docker
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Status complete."
exit 0
