#!/usr/bin/env bash
# NCP Module: build-tools — Upgrade Hook
# Category: system
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="build-tools"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running upgrade (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement upgrade logic for build-tools
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Upgrade complete."
exit 0
