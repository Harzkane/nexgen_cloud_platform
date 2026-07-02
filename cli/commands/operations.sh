#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP) CLI — Operations Command
# ============================================================

set -euo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CMD_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/engine/operations.sh"

main() {
    log_section "NCP Operations History"

    # Header
    printf "  %-20s  %-15s  %-10s  %-10s  %-10s\n" "TIMESTAMP" "OPERATION ID" "TYPE" "DURATION" "STATUS"
    printf "  %s\n" "--------------------------------------------------------------------------------"

    local history
    history=$(get_operations_history)

    if [ -z "$history" ]; then
        echo "  No operations recorded."
        echo ""
        exit 0
    fi

    # Print log rows
    while IFS= read -r row; do
        [ -z "$row" ] && continue
        local ts op_id type dur status
        ts=$(echo "$row" | cut -d'|' -f1)
        op_id=$(echo "$row" | cut -d'|' -f2)
        type=$(echo "$row" | cut -d'|' -f3)
        dur=$(echo "$row" | cut -d'|' -f4)
        status=$(echo "$row" | cut -d'|' -f5)

        local status_icon="✔"
        [ "$status" = "FAILED" ] && status_icon="✘"

        printf "  %-20s  %-15s  %-10s  %-10s  %-10s %s\n" "$ts" "$op_id" "$type" "${dur}s" "$status" "$status_icon"
    done <<< "$history"
    echo ""
}

main "$@"
