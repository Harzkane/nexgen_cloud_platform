#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Manifest Loader Engine
# ============================================================

set -euo pipefail

LOADER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LOADER_DIR/parser.sh"
source "$LOADER_DIR/validator.sh"

# Load a manifest file into the environment with a given prefix.
# Runs validation first, and only loads if validation passes.
# Usage: load_manifest <file_path> [prefix]
load_manifest() {
    local yaml_file="$1"
    local prefix="${2:-NCP_MANIFEST_}"

    if [ ! -f "$yaml_file" ]; then
        echo "Error: Manifest file not found at $yaml_file" >&2
        return 1
    fi

    # 1. Validate manifest first
    if ! validate_manifest "$yaml_file"; then
        echo "Error: Manifest validation failed for $yaml_file" >&2
        return 1
    fi

    # 2. Parse manifest fields
    if ! parse_manifest "$yaml_file" "$prefix"; then
        echo "Error: Failed to parse manifest fields at $yaml_file" >&2
        return 1
    fi

    return 0
}
