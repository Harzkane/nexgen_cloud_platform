#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Automated Integration Test Suite
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

# Source assertion helpers
source "$PROJECT_ROOT/core/utils/output.sh"

# Set up test environment
export NCP_STATE_STORE_DIR="$PROJECT_ROOT/tests/fixtures/integration/state"
export NCP_TXN_STORE_DIR="$PROJECT_ROOT/tests/fixtures/integration/transactions"
export NCP_OPS_STORE_DIR="$PROJECT_ROOT/tests/fixtures/integration/operations"

rm -rf "$NCP_STATE_STORE_DIR" "$NCP_TXN_STORE_DIR" "$NCP_OPS_STORE_DIR"
mkdir -p "$NCP_STATE_STORE_DIR" "$NCP_TXN_STORE_DIR" "$NCP_OPS_STORE_DIR"

source "$PROJECT_ROOT/core/state/state.sh"
source "$PROJECT_ROOT/core/engine/operations.sh"

# Define mock module path in system category
MOCK_MODULE_DIR="$PROJECT_ROOT/modules/system/mock-integration-comp"

# Cleanup function to run on exit
cleanup() {
    rm -rf "$MOCK_MODULE_DIR"
    rm -rf "$NCP_STATE_STORE_DIR" "$NCP_TXN_STORE_DIR" "$NCP_OPS_STORE_DIR"
}
trap cleanup EXIT INT TERM

# Create mock component structure
mkdir -p "$MOCK_MODULE_DIR"

cat <<EOF > "$MOCK_MODULE_DIR/manifest.yml"
apiVersion: ncp.io/v1
kind: Module
id: mock-integration-comp
name: mock-integration-comp
displayName: Mock Integration Component
version: 0.1.0
category: system
lifecycle:
  install:
    script: install.sh
    requiresSudo: false
  verify:
    script: verify.sh
  status:
    script: status.sh
EOF

cat <<EOF > "$MOCK_MODULE_DIR/install.sh"
#!/usr/bin/env bash
set -euo pipefail
MODULE_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="\$(cd "\$MODULE_DIR/../../.." && pwd)"
source "\$PROJECT_ROOT/core/state/state.sh"
source "\$PROJECT_ROOT/core/platform/resources.sh"

# Use Resources API to trigger transaction logging
ensure_directory "/tmp/mock-integration-dir"
mark_installed "mock-integration-comp" "0.1.0"
exit 0
EOF
chmod +x "$MOCK_MODULE_DIR/install.sh"

cat <<EOF > "$MOCK_MODULE_DIR/status.sh"
#!/usr/bin/env bash
set -euo pipefail
MODULE_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="\$(cd "\$MODULE_DIR/../../.." && pwd)"
source "\$PROJECT_ROOT/core/state/state.sh"

# Return 0 if healthy, 2 if drifted, 3 if not installed
if is_installed "mock-integration-comp"; then
    if [ ! -d "/tmp/mock-integration-dir" ]; then
        exit 2 # Drifted!
    fi
    exit 0
fi
exit 3
EOF
chmod +x "$MOCK_MODULE_DIR/status.sh"

cat <<EOF > "$MOCK_MODULE_DIR/verify.sh"
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$MOCK_MODULE_DIR/verify.sh"

pass_count=0
fail_count=0

assert_success() {
    local rc="$1"
    local label="$2"
    if [ "$rc" -eq 0 ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (exit $rc)"
        fail_count=$((fail_count + 1))
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local label="$3"
    if [ "$expected" = "$actual" ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (expected '$expected', got '$actual')"
        fail_count=$((fail_count + 1))
    fi
}

# ── Test Cases ────────────────────────────────────────────────────────────────

test_cli_plan() {
    echo "Running integration: CLI plan command..."
    local out
    out=$(bash "$PROJECT_ROOT/cli/ncp" plan mock-integration-comp 2>&1)
    local rc=$?
    assert_success $rc "CLI plan command succeeds"
    if echo "$out" | grep -q "Mock Integration Component"; then
        success "  [PASS] Plan output contains component details"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] Plan output did not contain component details"
        fail_count=$((fail_count + 1))
    fi
}

test_cli_install() {
    echo "Running integration: CLI install command..."
    # Clean up test directories
    rm -rf "/tmp/mock-integration-dir"

    local out
    out=$(bash "$PROJECT_ROOT/cli/ncp" install mock-integration-comp 2>&1)
    local rc=$?
    assert_success $rc "CLI install command succeeds"

    # Verify component state is written
    local status
    status=$(get_component_state "mock-integration-comp" "status")
    assert_equals "INSTALLED" "$status" "State store marks component as INSTALLED"
}

test_cli_operations() {
    echo "Running integration: CLI operations command..."
    local out
    out=$(bash "$PROJECT_ROOT/cli/ncp" operations 2>&1)
    local rc=$?
    assert_success $rc "CLI operations command succeeds"

    if echo "$out" | grep -q "install.*SUCCESS"; then
        success "  [PASS] Operations log displays successful install run"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] Operations history didn't list install operation"
        fail_count=$((fail_count + 1))
    fi
}

test_cli_drift_detection() {
    echo "Running integration: CLI status check-drift..."

    # Check status without drift (should be healthy)
    local rc=0
    bash "$PROJECT_ROOT/cli/ncp" status --check-drift mock-integration-comp >/dev/null 2>&1 || rc=$?
    assert_success $rc "Component is reconciled and healthy"

    # Manually delete directory to simulate drift
    rm -rf "/tmp/mock-integration-dir"

    local rc_drift=0
    bash "$PROJECT_ROOT/cli/ncp" status --check-drift mock-integration-comp >/dev/null 2>&1 || rc_drift=$?
    if [ "$rc_drift" -eq 2 ]; then
        success "  [PASS] CLI status --check-drift returned exit code 2 (DRIFTED)"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] Expected exit code 2 on drift, got $rc_drift"
        fail_count=$((fail_count + 1))
    fi

    # Verify State Manager registers DRIFTED status
    local status
    status=$(get_component_state "mock-integration-comp" "status")
    assert_equals "DRIFTED" "$status" "State Manager transitions status to DRIFTED"
}

# ── Run ───────────────────────────────────────────────────────────────────────

echo "==========================================="
echo " NCP Integration Test Suite"
echo "==========================================="

test_cli_plan
test_cli_install
test_cli_operations
test_cli_drift_detection

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count integration test(s) failed."
    exit 1
fi

success "All integration tests passed!"
