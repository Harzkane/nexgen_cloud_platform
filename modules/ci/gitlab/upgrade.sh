#!/usr/bin/env bash
# NCP Module: gitlab — Upgrade Hook
# Category: ci
# Version: $(cat "$(dirname "$0")/VERSION")
set -euo pipefail

MODULE_NAME="gitlab"
MODULE_DIR="$(dirname "$(realpath "$0")")"
MODULE_VERSION="$(cat "$MODULE_DIR/VERSION")"

echo "[$MODULE_NAME] Running upgrade (v$MODULE_VERSION)..."

# ─────────────────────────────────────────
# TODO: Implement upgrade logic for gitlab
# ─────────────────────────────────────────

echo "[$MODULE_NAME] Upgrade complete."
exit 0
