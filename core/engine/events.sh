#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Namespaced Lifecycle Event Bus
# ============================================================
# Full component lifecycle event namespace (component:* style):
#
#   component:plan              — component added to execution plan
#   component:before_status     — about to run status check
#   component:after_status      — status check complete
#   component:before_install    — about to run install hook
#   component:after_install     — install hook complete
#   component:before_verify     — about to run verify hook
#   component:after_verify      — verify hook complete
#   component:before_configure  — about to run configure hook
#   component:after_configure   — configure hook complete
#   component:failure           — any hook failed
#   component:rollback          — component is being rolled back
#   component:complete          — component fully installed & verified
#
# Operation-level events:
#   operation:started           — operation run began
#   operation:finished          — operation run ended
#   operation:failed            — operation run failed
#   operation:rollback:before   — rollback about to start
#   operation:rollback:after    — rollback completed
#
# Planner events:
#   planner:plan:created        — plan built successfully
#   planner:plan:failed         — plan build failed
# ============================================================

set -euo pipefail

EVENTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$EVENTS_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"

# ---------------------------------------------------------------------------
# publish_event <event_name> <component_or_op_id> [payload]
#
# Writes a structured event log entry and, when a session is active,
# also appends to the session's events.log for per-run auditing.
# ---------------------------------------------------------------------------
publish_event() {
    local event_name="$1"
    local entity_id="$2"
    local payload="${3:-}"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Structured log line
    local log_line
    log_line="EVENT [$event_name] entity='$entity_id' ts='$timestamp'${payload:+ payload=\"$payload\"}"
    log_info "$log_line"

    # If a session is active, append structured JSON-style entry to session events.log
    if [ -n "${NCP_SESSION_EVENTS_LOG:-}" ] && [ -f "${NCP_SESSION_EVENTS_LOG}" ]; then
        echo "{\"ts\":\"${timestamp}\",\"event\":\"${event_name}\",\"entity\":\"${entity_id}\",\"payload\":\"${payload}\"}" \
            >> "$NCP_SESSION_EVENTS_LOG"
    fi
}
