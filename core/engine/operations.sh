#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Operations Engine
# ============================================================
# Coordinates all top-level operation types (install, reconcile,
# rollback) under a unique Execution Session that bundles all
# artefacts for auditing, crash recovery, and future GUI.
# ============================================================

set -euo pipefail

OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$OPERATIONS_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/discovery/modules.sh"
source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/engine/planner.sh"
source "$PROJECT_ROOT/core/engine/installer.sh"
source "$PROJECT_ROOT/core/engine/reconciler.sh"
source "$PROJECT_ROOT/core/engine/rollback.sh"
source "$PROJECT_ROOT/core/engine/session.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"
source "$PROJECT_ROOT/core/engine/events.sh"

NCP_OPS_STORE_DIR="${PROJECT_ROOT}/workspace/operations"
mkdir -p "$NCP_OPS_STORE_DIR"
HISTORY_FILE="$NCP_OPS_STORE_DIR/history.log"
[ -f "$HISTORY_FILE" ] || touch "$HISTORY_FILE"

# ---------------------------------------------------------------------------
# run_operation <type> [args...]
#
# Runs an operation under an Execution Session.
# Session artefacts are written to workspace/sessions/<session-id>/
# ---------------------------------------------------------------------------
run_operation() {
    local type="$1"
    shift
    local args=("$@")

    # ── 1. Start Execution Session ───────────────────────────────────────────
    begin_session "$type"
    local session_id="$NCP_SESSION_ID"

    local op_id
    op_id="op-$(date +%s)"

    # ── 2. Discover and register all modules ─────────────────────────────────
    local modules
    modules=$(discover_modules)
    local module_path
    while IFS= read -r module_path; do
        [ -z "$module_path" ] && continue
        local mf="$module_path/manifest.yml"
        [ -f "$mf" ] || continue
        register_component "$module_path" > /dev/null 2>&1 || true
    done <<< "$modules"

    # ── 3. Start transaction (linked to session) ──────────────────────────────
    start_transaction "$op_id" "$type" "$session_id"
    publish_event "operation:started" "$op_id" "$type"
    local start_time
    start_time=$(date +%s)

    local rc=0

    # ── 4. Execute operation ──────────────────────────────────────────────────
    case "$type" in
        install)
            log_info "Starting Operation $op_id: install targets=${args[*]}"
            local plan=""
            if ! plan=$(build_plan "${args[@]}" 2>&1); then
                log_error "Planning failed: $plan"
                publish_event "planner:plan:failed" "$op_id" "$plan"
                fail_transaction
                rc=1
            else
                # Write resolved plan into session artefact
                write_session_plan "$(get_plan_components "$plan")"
                publish_event "planner:plan:created" "$op_id"

                print_plan "$plan"
                if ! install_plan_execution "$plan"; then
                    log_error "Installation failed. Triggering rollback..."
                    publish_event "operation:failed" "$op_id" "install"
                    fail_transaction
                    rollback_transaction "$op_id" || true
                    rc=1
                fi
            fi
            ;;
        reconcile)
            log_info "Starting Operation $op_id: reconcile targets=${args[*]}"
            local target
            for target in "${args[@]}"; do
                reconcile_component "$target" || rc=$?
            done
            ;;
        rollback)
            log_info "Starting Operation $op_id: rollback txn=${args[0]:-}"
            if [ -z "${args[0]:-}" ]; then
                log_error "No transaction ID specified for rollback."
                fail_transaction
                rc=1
            else
                rollback_transaction "${args[0]}" || rc=$?
            fi
            ;;
        *)
            log_error "Unknown operation type: $type"
            fail_transaction
            rc=1
            ;;
    esac

    # ── 5. Finalize ───────────────────────────────────────────────────────────
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    local status="SUCCESS"
    if [ "$rc" -ne 0 ]; then
        status="FAILED"
    else
        commit_transaction
    fi

    # Finalize session — writes state.json
    finalize_session "$status"

    # Append to operations history log (includes session path for traceability)
    local session_path="${NCP_SESSIONS_DIR:-${PROJECT_ROOT}/workspace/sessions}/${session_id}"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$op_id|$type|${duration}s|$status|$session_id" >> "$HISTORY_FILE"

    publish_event "operation:finished" "$op_id" "$status"

    return "$rc"
}

# ---------------------------------------------------------------------------
# get_operations_history — print all operation history entries
# ---------------------------------------------------------------------------
get_operations_history() {
    if [ ! -f "$HISTORY_FILE" ]; then
        return
    fi
    cat "$HISTORY_FILE"
}
