#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Execution Session Manager
# ============================================================
# Every operation run gets a unique session that bundles all
# artefacts for that run into one directory:
#
#   workspace/sessions/<session-id>/
#     plan.json      — resolved component plan
#     events.log     — all events published during the run
#     rollback.log   — rollback details if triggered
#     state.json     — final component states at end of run
#
# This enables: history, audit, crash recovery, resume, GUI.
# ============================================================

set -euo pipefail

SESSION_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SESSION_SH_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"

NCP_SESSIONS_DIR="${NCP_SESSIONS_DIR:-${PROJECT_ROOT}/workspace/sessions}"
mkdir -p "$NCP_SESSIONS_DIR"

# Exported globals — consumed by events.sh and operations.sh
NCP_SESSION_ID=""
NCP_SESSION_DIR=""
NCP_SESSION_EVENTS_LOG=""
NCP_SESSION_ROLLBACK_LOG=""

# ---------------------------------------------------------------------------
# begin_session [type]
# Creates the session directory and initialises artefact files.
# Sets NCP_SESSION_ID, NCP_SESSION_DIR, NCP_SESSION_EVENTS_LOG,
# NCP_SESSION_ROLLBACK_LOG in the calling environment.
# ---------------------------------------------------------------------------
begin_session() {
    local type="${1:-operation}"

    NCP_SESSION_ID="$(date '+%Y%m%d-%H%M%S')-$$"
    NCP_SESSION_DIR="${NCP_SESSIONS_DIR}/${NCP_SESSION_ID}"
    mkdir -p "$NCP_SESSION_DIR"

    # Initialise artefact files
    NCP_SESSION_EVENTS_LOG="${NCP_SESSION_DIR}/events.log"
    NCP_SESSION_ROLLBACK_LOG="${NCP_SESSION_DIR}/rollback.log"

    touch "$NCP_SESSION_EVENTS_LOG"
    touch "$NCP_SESSION_ROLLBACK_LOG"

    # Write plan.json stub (populated by caller after planning)
    echo "{\"session_id\":\"${NCP_SESSION_ID}\",\"type\":\"${type}\",\"started\":\"$(date '+%Y-%m-%d %H:%M:%S')\",\"plan\":[]}" \
        > "${NCP_SESSION_DIR}/plan.json"

    # Export so child functions/scripts see these values
    export NCP_SESSION_ID NCP_SESSION_DIR NCP_SESSION_EVENTS_LOG NCP_SESSION_ROLLBACK_LOG

    log_info "Execution Session started: $NCP_SESSION_ID"
    log_info "Session artefacts: $NCP_SESSION_DIR"
}

# ---------------------------------------------------------------------------
# write_session_plan <plan_components_newline_list>
# Rewrites plan.json with actual component list.
# ---------------------------------------------------------------------------
write_session_plan() {
    local components="$1"
    [ -z "${NCP_SESSION_DIR:-}" ] && return 0

    local comp_json="[]"
    if [ -n "$components" ]; then
        # Build JSON array from newline-separated component list
        local json_items=""
        while IFS= read -r comp; do
            [ -z "$comp" ] && continue
            json_items="${json_items}\"${comp}\","
        done <<< "$components"
        json_items="${json_items%,}"   # strip trailing comma
        comp_json="[${json_items}]"
    fi

    echo "{\"session_id\":\"${NCP_SESSION_ID}\",\"type\":\"install\",\"started\":\"$(date '+%Y-%m-%d %H:%M:%S')\",\"plan\":${comp_json}}" \
        > "${NCP_SESSION_DIR}/plan.json"
}

# ---------------------------------------------------------------------------
# log_session_rollback <message>
# Appends a line to the session's rollback.log.
# ---------------------------------------------------------------------------
log_session_rollback() {
    local message="$1"
    if [ -n "${NCP_SESSION_ROLLBACK_LOG:-}" ] && [ -f "$NCP_SESSION_ROLLBACK_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$NCP_SESSION_ROLLBACK_LOG"
    fi
}

# ---------------------------------------------------------------------------
# finalize_session <status> [component_states_json]
# Writes state.json and marks session complete.
# ---------------------------------------------------------------------------
finalize_session() {
    local status="${1:-UNKNOWN}"
    [ -z "${NCP_SESSION_DIR:-}" ] && return 0

    # Write state.json
    echo "{\"session_id\":\"${NCP_SESSION_ID}\",\"status\":\"${status}\",\"finished\":\"$(date '+%Y-%m-%d %H:%M:%S')\"}" \
        > "${NCP_SESSION_DIR}/state.json"

    log_info "Execution Session finalized: $NCP_SESSION_ID → $status"

    # Reset globals
    NCP_SESSION_ID=""
    NCP_SESSION_DIR=""
    NCP_SESSION_EVENTS_LOG=""
    NCP_SESSION_ROLLBACK_LOG=""

    export NCP_SESSION_ID NCP_SESSION_DIR NCP_SESSION_EVENTS_LOG NCP_SESSION_ROLLBACK_LOG
}

# ---------------------------------------------------------------------------
# get_session_dir — echo the current session directory path
# ---------------------------------------------------------------------------
get_session_dir() {
    echo "${NCP_SESSION_DIR:-}"
}

# ---------------------------------------------------------------------------
# list_sessions — list all session directories newest-first
# ---------------------------------------------------------------------------
list_sessions() {
    ls -1t "$NCP_SESSIONS_DIR" 2>/dev/null || true
}
