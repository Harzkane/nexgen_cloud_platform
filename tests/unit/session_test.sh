#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Unit Test: Execution Session Manager
# ============================================================
# Verifies:
#   1. begin_session creates workspace/sessions/<id>/ directory
#   2. plan.json, events.log, rollback.log are created
#   3. write_session_plan populates plan.json
#   4. log_session_rollback appends to rollback.log
#   5. finalize_session writes state.json and clears globals
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

source "$PROJECT_ROOT/core/utils/output.sh"

# ── Isolation sandbox — redirect sessions to fixtures ─────────────────────────
export NCP_SESSIONS_DIR="$PROJECT_ROOT/tests/fixtures/sessions"
rm -rf "$NCP_SESSIONS_DIR"
mkdir -p "$NCP_SESSIONS_DIR"

source "$PROJECT_ROOT/core/engine/session.sh"

pass_count=0
fail_count=0

assert_exists() {
    local path="$1" label="$2"
    if [ -e "$path" ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (expected '$path' to exist)"
        fail_count=$((fail_count + 1))
    fi
}

assert_equals() {
    local expected="$1" actual="$2" label="$3"
    if [ "$expected" = "$actual" ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (expected '$expected', got '$actual')"
        fail_count=$((fail_count + 1))
    fi
}

assert_file_contains() {
    local path="$1" pattern="$2" label="$3"
    if grep -q "$pattern" "$path" 2>/dev/null; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (pattern '$pattern' not found in '$path')"
        fail_count=$((fail_count + 1))
    fi
}

assert_empty() {
    local value="$1" label="$2"
    if [ -z "$value" ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (expected empty, got '$value')"
        fail_count=$((fail_count + 1))
    fi
}

# ── Test 1: Session directory and artefact files created ─────────────────────
test_session_begin_creates_artefacts() {
    echo "Running unit: session begin creates artefacts..."

    begin_session "install" > /dev/null 2>&1

    local session_dir="$NCP_SESSION_DIR"

    assert_exists "$session_dir"               "Session directory created"
    assert_exists "$session_dir/plan.json"     "plan.json created"
    assert_exists "$session_dir/events.log"    "events.log created"
    assert_exists "$session_dir/rollback.log"  "rollback.log created"

    assert_file_contains "$session_dir/plan.json" "session_id" "plan.json contains session_id"
}

# ── Test 2: write_session_plan populates plan.json ────────────────────────────
test_write_session_plan() {
    echo "Running unit: write_session_plan..."

    write_session_plan "$(printf 'comp-a\ncomp-b\ncomp-c')" > /dev/null 2>&1

    local plan_file="$NCP_SESSION_DIR/plan.json"
    assert_file_contains "$plan_file" "comp-a" "plan.json contains comp-a"
    assert_file_contains "$plan_file" "comp-b" "plan.json contains comp-b"
    assert_file_contains "$plan_file" "comp-c" "plan.json contains comp-c"
}

# ── Test 3: log_session_rollback appends to rollback.log ─────────────────────
test_log_session_rollback() {
    echo "Running unit: log_session_rollback..."

    log_session_rollback "Rollback started for test-txn" > /dev/null 2>&1
    log_session_rollback "Reversing directory:/tmp/test-dir" > /dev/null 2>&1

    local rollback_file="$NCP_SESSION_DIR/rollback.log"
    assert_file_contains "$rollback_file" "Rollback started" "rollback.log contains start entry"
    assert_file_contains "$rollback_file" "Reversing directory" "rollback.log contains reversal entry"
}

# ── Test 4: NCP_SESSION_EVENTS_LOG is set for event bus wiring ───────────────
test_session_events_log_exported() {
    echo "Running unit: NCP_SESSION_EVENTS_LOG is exported..."

    # Should be non-empty while session is active
    if [ -n "${NCP_SESSION_EVENTS_LOG:-}" ]; then
        success "  [PASS] NCP_SESSION_EVENTS_LOG is set during active session"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] NCP_SESSION_EVENTS_LOG is empty during active session"
        fail_count=$((fail_count + 1))
    fi
}

# ── Test 5: finalize_session writes state.json and clears globals ─────────────
test_session_finalize() {
    echo "Running unit: finalize_session..."

    local session_dir="$NCP_SESSION_DIR"
    finalize_session "SUCCESS" > /dev/null 2>&1

    assert_exists "$session_dir/state.json" "state.json created after finalize"
    assert_file_contains "$session_dir/state.json" "SUCCESS" "state.json contains SUCCESS status"

    # Globals should be cleared
    assert_empty "${NCP_SESSION_ID:-}" "NCP_SESSION_ID cleared after finalize"
    assert_empty "${NCP_SESSION_DIR:-}" "NCP_SESSION_DIR cleared after finalize"
    assert_empty "${NCP_SESSION_EVENTS_LOG:-}" "NCP_SESSION_EVENTS_LOG cleared after finalize"
}

# ── Test 6: list_sessions returns session directories ────────────────────────
test_list_sessions() {
    echo "Running unit: list_sessions..."

    # Start and finalize a second session so there are entries to list
    begin_session "reconcile" > /dev/null 2>&1
    finalize_session "SUCCESS" > /dev/null 2>&1

    local session_count
    session_count=$(list_sessions | wc -l | tr -d ' ')

    if [ "$session_count" -ge 1 ]; then
        success "  [PASS] list_sessions returns at least 1 session ($session_count found)"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] list_sessions returned 0 sessions"
        fail_count=$((fail_count + 1))
    fi
}

# ── Run ───────────────────────────────────────────────────────────────────────
echo "==========================================="
echo " NCP Execution Session Unit Tests"
echo "==========================================="

test_session_begin_creates_artefacts
test_write_session_plan
test_log_session_rollback
test_session_events_log_exported
test_session_finalize
test_list_sessions

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count test(s) failed."
    exit 1
fi

success "All session tests passed!"
