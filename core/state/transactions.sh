#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Transaction Logging Service
# ============================================================
# Tracks every resource mutation during an operation so that
# rollback can selectively undo only what THIS run created.
#
# Transaction file structure:
#   transaction_id=<id>
#   type=<install|reconcile|...>
#   started=<timestamp>
#   status=ACTIVE|COMMITTED|FAILED|ROLLED_BACK
#   session_id=<session_id>
#   --- COMPONENTS_INSTALLED_THIS_RUN ---
#   <component_id>
#   --- COMPONENTS_ALREADY_PRESENT ---
#   <component_id>
#   --- RESOURCES ---
#   <res_type>|<target>|<meta>|<component_id>
# ============================================================

set -euo pipefail

TXN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TXN_DIR/../.." && pwd)"

NCP_TXN_STORE_DIR="${NCP_TXN_STORE_DIR:-${PROJECT_ROOT}/workspace/transactions}"
mkdir -p "$NCP_TXN_STORE_DIR"

# Globals holding active transaction context
ACTIVE_TXN_ID=""
ACTIVE_TXN_FILE=""

# ---------------------------------------------------------------------------
# begin_transaction <operation_id> <type> [session_id]
# ---------------------------------------------------------------------------
start_transaction() {
    local op_id="$1"
    local type="$2"
    local session_id="${3:-}"

    ACTIVE_TXN_ID="$op_id"
    ACTIVE_TXN_FILE="$NCP_TXN_STORE_DIR/txn-${ACTIVE_TXN_ID}.state"

    {
        echo "transaction_id=${ACTIVE_TXN_ID}"
        echo "type=${type}"
        echo "started=$(date '+%Y-%m-%d %H:%M:%S')"
        echo "status=ACTIVE"
        [ -n "$session_id" ] && echo "session_id=${session_id}"
        echo "--- COMPONENTS_INSTALLED_THIS_RUN ---"
        echo "--- COMPONENTS_ALREADY_PRESENT ---"
        echo "--- RESOURCES ---"
    } > "$ACTIVE_TXN_FILE"
}

# ---------------------------------------------------------------------------
# Record a component that was freshly installed by this operation.
# These are the ONLY components rollback should undo.
# ---------------------------------------------------------------------------
record_component_installed_this_run() {
    local comp_id="$1"
    if [ -n "${ACTIVE_TXN_FILE:-}" ] && [ -f "$ACTIVE_TXN_FILE" ]; then
        # Insert comp_id after the COMPONENTS_INSTALLED_THIS_RUN sentinel
        local temp_f
        temp_f=$(mktemp)
        awk -v comp="$comp_id" '
            /^--- COMPONENTS_INSTALLED_THIS_RUN ---/ { print; print comp; next }
            { print }
        ' "$ACTIVE_TXN_FILE" > "$temp_f"
        mv "$temp_f" "$ACTIVE_TXN_FILE"
    fi
}

# ---------------------------------------------------------------------------
# Record a component that was already present before this operation started.
# Rollback must NOT remove these.
# ---------------------------------------------------------------------------
record_component_already_present() {
    local comp_id="$1"
    if [ -n "${ACTIVE_TXN_FILE:-}" ] && [ -f "$ACTIVE_TXN_FILE" ]; then
        local temp_f
        temp_f=$(mktemp)
        awk -v comp="$comp_id" '
            /^--- COMPONENTS_ALREADY_PRESENT ---/ { print; print comp; next }
            { print }
        ' "$ACTIVE_TXN_FILE" > "$temp_f"
        mv "$temp_f" "$ACTIVE_TXN_FILE"
    fi
}

# ---------------------------------------------------------------------------
# Record a resource mutation in the active transaction.
# Usage: record_transaction_item <res_type> <target> [metadata] [component_id]
# ---------------------------------------------------------------------------
record_transaction_item() {
    local res_type="$1"
    local target="$2"
    local meta="${3:-}"
    local comp_id="${4:-}"

    if [ -n "${ACTIVE_TXN_FILE:-}" ] && [ -f "$ACTIVE_TXN_FILE" ]; then
        echo "${res_type}|${target}|${meta}|${comp_id}" >> "$ACTIVE_TXN_FILE"
    fi
}

# ---------------------------------------------------------------------------
# get_installed_this_run — echo list of component IDs installed this run
# ---------------------------------------------------------------------------
get_installed_this_run() {
    local txn_file="${1:-$ACTIVE_TXN_FILE}"
    [ -f "$txn_file" ] || return 0

    local in_section=false
    while IFS= read -r line; do
        if [ "$line" = "--- COMPONENTS_INSTALLED_THIS_RUN ---" ]; then
            in_section=true
            continue
        fi
        if [[ "$line" == "--- "* ]]; then
            in_section=false
            continue
        fi
        [ "$in_section" = "true" ] && [ -n "$line" ] && echo "$line"
    done < "$txn_file"
}

# ---------------------------------------------------------------------------
# commit_transaction
# ---------------------------------------------------------------------------
commit_transaction() {
    if [ -n "${ACTIVE_TXN_FILE:-}" ] && [ -f "$ACTIVE_TXN_FILE" ]; then
        local temp_f
        temp_f=$(mktemp)
        sed 's/^status=ACTIVE/status=COMMITTED/' "$ACTIVE_TXN_FILE" > "$temp_f"
        mv "$temp_f" "$ACTIVE_TXN_FILE"
    fi
    ACTIVE_TXN_ID=""
    ACTIVE_TXN_FILE=""
}

# ---------------------------------------------------------------------------
# fail_transaction — mark as FAILED but keep file for rollback to read
# ---------------------------------------------------------------------------
fail_transaction() {
    if [ -n "${ACTIVE_TXN_FILE:-}" ] && [ -f "$ACTIVE_TXN_FILE" ]; then
        local temp_f
        temp_f=$(mktemp)
        sed 's/^status=ACTIVE/status=FAILED/' "$ACTIVE_TXN_FILE" > "$temp_f"
        mv "$temp_f" "$ACTIVE_TXN_FILE"
    fi
    # Keep ACTIVE_TXN_ID / ACTIVE_TXN_FILE set so rollback can locate the file
}
