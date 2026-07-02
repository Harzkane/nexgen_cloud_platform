#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Unit Test: Resource Dispatcher & Providers Registry
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

source "$PROJECT_ROOT/core/utils/output.sh"

# Create a temporary mock resource provider inside core/resources/
MOCK_PROVIDER="${PROJECT_ROOT}/core/resources/mocktest.sh"

cat << 'EOF' > "$MOCK_PROVIDER"
#!/usr/bin/env bash
resource_mocktest_state() {
    echo "state:$1"
}
resource_mocktest_diff() {
    echo "diff:$1:$2"
}
resource_mocktest_apply() {
    echo "apply:$1:$2:$3"
}
EOF

source "$PROJECT_ROOT/core/engine/dispatcher.sh"

pass_count=0
fail_count=0

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

test_dispatcher_state() {
    echo "Running unit: dispatcher state action..."
    local out
    out=$(resource_dispatch "mocktest" "state" "my-target")
    assert_equals "state:my-target" "$out" "State action dispatched to provider"
}

test_dispatcher_diff() {
    echo "Running unit: dispatcher diff action..."
    local out
    out=$(resource_dispatch "mocktest" "diff" "my-target" "present")
    assert_equals "diff:my-target:present" "$out" "Diff action dispatched to provider"
}

test_dispatcher_apply() {
    echo "Running unit: dispatcher apply action..."
    local out
    out=$(resource_dispatch "mocktest" "apply" "my-target" "present" "my-comp")
    assert_equals "apply:my-target:present:my-comp" "$out" "Apply action dispatched to provider"
}

test_dispatcher_unknown_type() {
    echo "Running unit: dispatcher unknown type error..."
    local rc=0
    resource_dispatch "nonexistenttype" "state" "tgt" >/dev/null 2>&1 || rc=$?
    if [ "$rc" -ne 0 ]; then
        success "  [PASS] Unknown resource type returns non-zero code"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] Unknown resource type did not fail"
        fail_count=$((fail_count + 1))
    fi
}

echo "==========================================="
echo " NCP Resource Dispatcher Unit Tests"
echo "==========================================="

test_dispatcher_state
test_dispatcher_diff
test_dispatcher_apply
test_dispatcher_unknown_type

# Cleanup mock provider
rm -f "$MOCK_PROVIDER"

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count test(s) failed."
    exit 1
fi

success "All dispatcher tests passed!"
