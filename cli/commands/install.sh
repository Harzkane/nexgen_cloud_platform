#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP) CLI — Install Command
# ============================================================

set -euo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CMD_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/engine/operations.sh"

main() {
    if [ "${#}" -eq 0 ]; then
        echo "Usage: ncp install [--dry-run] <component_id> [component_id ...]" >&2
        exit 1
    fi

    # Check for dry-run
    local dry_run=false
    local -a targets
    for arg in "$@"; do
        if [ "$arg" = "--dry-run" ]; then
            dry_run=true
        else
            targets+=("$arg")
        fi
    done

    if [ "${#targets[@]}" -eq 0 ]; then
        echo "Usage: ncp install [--dry-run] <component_id> [component_id ...]" >&2
        exit 1
    fi

    if [ "$dry_run" = "true" ]; then
        # Run plan command
        bash "$PROJECT_ROOT/cli/commands/plan.sh" "${targets[@]}"
        exit 0
    fi

    # Trigger actual installation via Operations Engine
    if ! run_operation "install" "${targets[@]}"; then
        exit 1
    fi
}

main "$@"
