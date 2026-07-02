#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Unit Test: Event Bus (Expanded Lifecycle Namespace)
# ============================================================
# Verifies:
#   1. publish_event succeeds for all lifecycle event names
#   2. Event output contains structured format
#   3. When NCP_SESSION_EVENTS_LOG is set, events are written there
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

source "$PROJECT_ROOT/core/utils/output.sh"
source "$PROJECT_ROOT/core/engine/events.sh"

pass_count=0
fail_count=0

assert_success() {
    local rc="$1" label="$2"
    if [ "$rc" -eq 0 ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (exit $rc)"
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

# ── Test 1: All lifecycle event names publish without error ───────────────────
test_all_lifecycle_events_publish() {
    echo "Running unit: all lifecycle events publish successfully..."

    local events=(
        "component:plan"
        "component:before_status"
        "component:after_status"
        "component:before_install"
        "component:after_install"
        "component:before_verify"
        "component:after_verify"
        "component:before_configure"
        "component:after_configure"
        "component:failure"
        "component:rollback"
        "component:complete"
        "operation:started"
        "operation:finished"
        "operation:failed"
        "operation:rollback:before"
        "operation:rollback:after"
        "planner:plan:created"
        "planner:plan:failed"
    )

    local all_ok=true
    for event in "${events[@]}"; do
        local rc=0
        publish_event "$event" "test-entity" "test-payload" > /dev/null 2>&1 || rc=$?
        if [ "$rc" -ne 0 ]; then
            error "  [FAIL] Event '$event' failed to publish (exit $rc)"
            fail_count=$((fail_count + 1))
            all_ok=false
        fi
    done

    if [ "$all_ok" = "true" ]; then
        success "  [PASS] All ${#events[@]} lifecycle events published successfully"
        pass_count=$((pass_count + 1))
    fi
}

# ── Test 2: Structured log format ────────────────────────────────────────────
test_event_structured_format() {
    echo "Running unit: event structured log format..."

    local out
    out=$(publish_event "component:before_install" "git" "initiating installation" 2>&1)
    local rc=$?

    assert_success "$rc" "publish_event returns 0"

    if echo "$out" | grep -q "EVENT \[component:before_install\]"; then
        success "  [PASS] Event log uses structured [EVENT] format"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] Event log output did not match expected structure"
        error "  Output was: $out"
        fail_count=$((fail_count + 1))
    fi
}

# ── Test 3: Session events.log wiring ────────────────────────────────────────
test_event_writes_to_session_log() {
    echo "Running unit: events written to session events.log when active..."

    local tmp_events_log
    tmp_events_log=$(mktemp)
    export NCP_SESSION_EVENTS_LOG="$tmp_events_log"

    publish_event "component:complete" "nginx" "INSTALLED@v1.24" > /dev/null 2>&1

    assert_file_contains "$tmp_events_log" "component:complete" "Session events.log contains component:complete event"
    assert_file_contains "$tmp_events_log" "nginx" "Session events.log contains entity id"

    # Cleanup
    unset NCP_SESSION_EVENTS_LOG
    rm -f "$tmp_events_log"
}

# ── Test 4: No session log — no crash ────────────────────────────────────────
test_event_no_session_log_no_crash() {
    echo "Running unit: publish_event works when no session is active..."

    unset NCP_SESSION_EVENTS_LOG 2>/dev/null || true

    local rc=0
    publish_event "operation:started" "op-001" > /dev/null 2>&1 || rc=$?
    assert_success "$rc" "publish_event works without NCP_SESSION_EVENTS_LOG set"
}

# ── Run ───────────────────────────────────────────────────────────────────────
echo "==========================================="
echo " NCP Event Bus Unit Tests"
echo "==========================================="

test_all_lifecycle_events_publish
test_event_structured_format
test_event_writes_to_session_log
test_event_no_session_log_no_crash

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count test(s) failed."
    exit 1
fi

success "All event bus tests passed!"
