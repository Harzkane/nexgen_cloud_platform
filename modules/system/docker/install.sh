#!/usr/bin/env bash
# NCP Module: docker — Install Hook
# Category: system
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="docker"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running install (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement install logic for docker
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Install complete."
exit 0
