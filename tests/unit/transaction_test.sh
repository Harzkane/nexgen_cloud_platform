#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Unit Test: Transactions & Rollback (Reviewer Refinements)
# ============================================================
# Verifies:
#   1. installed_this_run[] is recorded separately from already_present[]
#   2. Rollback only undoes installed_this_run resources
#   3. Pre-existing component resources are NOT touched by rollback
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

source "$PROJECT_ROOT/core/utils/output.sh"

# ── Isolation sandbox ─────────────────────────────────────────────────────────
export NCP_TXN_STORE_DIR="$PROJECT_ROOT/tests/fixtures/transactions"
rm -rf "$NCP_TXN_STORE_DIR"
mkdir -p "$NCP_TXN_STORE_DIR"

source "$PROJECT_ROOT/core/state/transactions.sh"
source "$PROJECT_ROOT/core/engine/rollback.sh"

pass_count=0
fail_count=0

# ── Assertion helpers ─────────────────────────────────────────────────────────
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

assert_not_exists() {
    local path="$1" label="$2"
    if [ ! -e "$path" ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (expected '$path' NOT to exist)"
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

# ── Test 1: Basic transaction logging ─────────────────────────────────────────
test_transaction_logging() {
    echo "Running unit: transaction logging..."
    start_transaction "test-txn-log" "install"

    record_transaction_item "directory" "/tmp/ncp-log-dir" "created" "comp-a"
    record_transaction_item "file"      "/tmp/ncp-log-file" "created" "comp-a"

    commit_transaction

    local txn_file="$NCP_TXN_STORE_DIR/txn-test-txn-log.state"
    assert_exists "$txn_file" "Transaction log file was created"
    assert_file_contains "$txn_file" "status=COMMITTED" "Transaction marked COMMITTED"
}

# ── Test 2: installed_this_run tracking ───────────────────────────────────────
test_installed_this_run_tracking() {
    echo "Running unit: installed_this_run tracking..."
    start_transaction "test-txn-tracking" "install"

    record_component_already_present "existing-comp"
    record_component_installed_this_run "new-comp"

    local txn_file="$NCP_TXN_STORE_DIR/txn-test-txn-tracking.state"

    assert_file_contains "$txn_file" "existing-comp" "already_present comp recorded"
    assert_file_contains "$txn_file" "new-comp" "installed_this_run comp recorded"

    # get_installed_this_run should return only new-comp
    local installed
    installed=$(get_installed_this_run "$txn_file")
    if echo "$installed" | grep -q "new-comp"; then
        success "  [PASS] get_installed_this_run returns newly installed comp"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] get_installed_this_run did not return new-comp"
        fail_count=$((fail_count + 1))
    fi

    if ! echo "$installed" | grep -q "existing-comp"; then
        success "  [PASS] get_installed_this_run excludes already_present comp"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] get_installed_this_run incorrectly included existing-comp"
        fail_count=$((fail_count + 1))
    fi

    commit_transaction
}

# ── Test 3: Rollback only undoes installed_this_run ───────────────────────────
test_selective_rollback() {
    echo "Running unit: selective rollback (installed_this_run only)..."

    # Create two dirs — one for an already-present comp, one for this-run comp
    local existing_dir="/tmp/ncp-existing-comp-dir"
    local new_dir="/tmp/ncp-new-comp-dir"

    rm -rf "$existing_dir" "$new_dir"
    mkdir -p "$existing_dir"
    mkdir -p "$new_dir"

    start_transaction "test-selective-rollback" "install"

    # existing-comp was already there — record as already_present
    record_component_already_present "existing-comp"
    record_transaction_item "directory" "$existing_dir" "created" "existing-comp"

    # new-comp was freshly installed — record as installed_this_run
    record_component_installed_this_run "new-comp"
    record_transaction_item "directory" "$new_dir" "created" "new-comp"

    fail_transaction

    local rc=0
    rollback_transaction "test-selective-rollback" > /dev/null 2>&1 || rc=$?
    assert_success "$rc" "rollback_transaction returns 0"

    # new-comp's directory should be gone
    assert_not_exists "$new_dir" "new-comp directory removed by rollback"

    # existing-comp's directory should still be there
    assert_exists "$existing_dir" "existing-comp directory NOT removed (was pre-existing)"

    rm -rf "$existing_dir"
}

# ── Test 4: Rollback with nothing installed_this_run ─────────────────────────
test_rollback_noop_when_nothing_installed() {
    echo "Running unit: rollback noop when nothing installed this run..."

    start_transaction "test-noop-rollback" "install"
    record_component_already_present "pre-existing-comp"
    record_transaction_item "directory" "/tmp/ncp-pre-existing" "created" "pre-existing-comp"
    fail_transaction

    local rc=0
    rollback_transaction "test-noop-rollback" > /dev/null 2>&1 || rc=$?
    assert_success "$rc" "Rollback noop returns 0 (nothing to undo)"
}

# ── Run ───────────────────────────────────────────────────────────────────────
echo "==========================================="
echo " NCP Transactions & Rollback Unit Tests"
echo "==========================================="

test_transaction_logging
test_installed_this_run_tracking
test_selective_rollback
test_rollback_noop_when_nothing_installed

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count test(s) failed."
    exit 1
fi

success "All transaction & rollback tests passed!"
