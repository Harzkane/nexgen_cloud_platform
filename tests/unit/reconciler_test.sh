#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Unit Test: Reconciler (Declarative Drift & Fallbacks)
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

source "$PROJECT_ROOT/core/utils/output.sh"

# Create a temporary mock resource provider for the declarative path
MOCK_PROVIDER="${PROJECT_ROOT}/core/resources/mockreconcile.sh"

cat << 'EOF' > "$MOCK_PROVIDER"
#!/usr/bin/env bash
resource_mockreconcile_state() {
    echo "present"
}
resource_mockreconcile_diff() {
    local target="$1"
    if [ "$target" = "drifted-res" ]; then
        echo "DRIFTED"
    else
        echo "SATISFIED"
    fi
}
EOF

# Isolation test sandbox
export NCP_STATE_STORE_DIR="$PROJECT_ROOT/tests/fixtures/reconciler"
rm -rf "$NCP_STATE_STORE_DIR"
mkdir -p "$NCP_STATE_STORE_DIR"

source "$PROJECT_ROOT/core/state/state.sh"
source "$PROJECT_ROOT/core/engine/reconciler.sh"

pass_count=0
fail_count=0

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

# ── Mock check_resource_state (Explicit checks stub) ─────────────────────────
check_resource_state() {
    local type="$1"
    local target="$2"

    case "$target" in
        healthy-target)  return 0 ;;   # SATISFIED
        drifted-target)  return 1 ;;   # UNSATISFIED
        *)               return 1 ;;
    esac
}

get_component_property() {
    echo "0.1.0"
}

# Stub registry checks
is_component_registered() {
    return 0
}

# ── Test 1: Explicit Resource API checks — healthy ───────────────────────────
test_reconciler_healthy_via_explicit_checks() {
    echo "Running unit: reconciler healthy via explicit checks..."

    # Reset resources variables so has_desired_resources is false
    unset NCP_COMP_healthy_comp_resources_count || true

    reconcile_component "healthy-comp" "package:healthy-target" > /dev/null 2>&1

    local status
    status=$(get_component_state "healthy-comp" "status")
    assert_equals "INSTALLED" "$status" "Healthy component → INSTALLED"
}

# ── Test 2: Explicit Resource API checks — drifted ───────────────────────────
test_reconciler_drifted_via_explicit_checks() {
    echo "Running unit: reconciler drifted via explicit checks..."

    # Reset resources variables so has_desired_resources is false
    unset NCP_COMP_drifted_comp_resources_count || true

    reconcile_component "drifted-comp" "package:drifted-target" > /dev/null 2>&1 || true

    local status
    status=$(get_component_state "drifted-comp" "status")
    assert_equals "DRIFTED" "$status" "Drifted component → DRIFTED"
}

# ── Test 3: Declarative Desired State path — healthy ──────────────────────────
test_reconciler_declarative_healthy() {
    echo "Running unit: reconciler healthy via declarative desired state..."

    export NCP_COMP_decl_healthy_resources_count=1
    export NCP_COMP_decl_healthy_resources_0_type="mockreconcile"
    export NCP_COMP_decl_healthy_resources_0_name="satisfied-res"
    export NCP_COMP_decl_healthy_resources_0_state="present"

    # Set valid desired state hash first (Refinement 4)
    local hash
    hash=$(compute_desired_state_hash "decl-healthy")
    set_component_state "decl-healthy" "desired_hash" "$hash"

    reconcile_component "decl-healthy" > /dev/null 2>&1

    local status
    status=$(get_component_state "decl-healthy" "status")
    assert_equals "INSTALLED" "$status" "Declarative satisfied component → INSTALLED"
}

# ── Test 4: Declarative Desired State path — drifted ──────────────────────────
test_reconciler_declarative_drifted() {
    echo "Running unit: reconciler drifted via declarative desired state..."

    export NCP_COMP_decl_drifted_resources_count=1
    export NCP_COMP_decl_drifted_resources_0_type="mockreconcile"
    export NCP_COMP_decl_drifted_resources_0_name="drifted-res"
    export NCP_COMP_decl_drifted_resources_0_state="present"

    local hash
    hash=$(compute_desired_state_hash "decl-drifted")
    set_component_state "decl-drifted" "desired_hash" "$hash"

    reconcile_component "decl-drifted" > /dev/null 2>&1 || true

    local status
    status=$(get_component_state "decl-drifted" "status")
    assert_equals "DRIFTED" "$status" "Declarative drifted component → DRIFTED"
}

# ── Test 4b: Declarative Desired State path — hash mismatch ───────────────────
test_reconciler_declarative_hash_mismatch() {
    echo "Running unit: reconciler hash mismatch via declarative desired state..."

    export NCP_COMP_decl_mismatch_resources_count=1
    export NCP_COMP_decl_mismatch_resources_0_type="mockreconcile"
    export NCP_COMP_decl_mismatch_resources_0_name="satisfied-res"
    export NCP_COMP_decl_mismatch_resources_0_state="present"

    # Set a wrong / mismatched hash
    set_component_state "decl-mismatch" "desired_hash" "outdated-hash-fingerprint"

    reconcile_component "decl-mismatch" > /dev/null 2>&1 || true

    local status
    status=$(get_component_state "decl-mismatch" "status")
    assert_equals "DRIFTED" "$status" "Hash mismatch component → DRIFTED"
}

# ── Test 5: Fallback — no resource checks, legacy status hook ─────────────────
execute_lifecycle_hook() {
    local comp_id="$1"
    local hook="$2"
    [ "$hook" = "status" ] || return 0
    case "$comp_id" in
        legacy-healthy) return 0 ;;
        legacy-drifted) return 2 ;;
        *)              return 3 ;;
    esac
}

test_reconciler_fallback_healthy() {
    echo "Running unit: reconciler fallback — healthy via legacy hook..."

    # Reset resources variables so has_desired_resources is false
    unset NCP_COMP_legacy_healthy_resources_count || true

    reconcile_component "legacy-healthy" > /dev/null 2>&1

    local status
    status=$(get_component_state "legacy-healthy" "status")
    assert_equals "INSTALLED" "$status" "Legacy healthy hook → INSTALLED"
}

test_reconciler_fallback_drifted() {
    echo "Running unit: reconciler fallback — drifted via legacy hook..."

    # Reset resources variables so has_desired_resources is false
    unset NCP_COMP_legacy_drifted_resources_count || true

    reconcile_component "legacy-drifted" > /dev/null 2>&1 || true

    local status
    status=$(get_component_state "legacy-drifted" "status")
    assert_equals "DRIFTED" "$status" "Legacy drifted hook → DRIFTED"
}

# ── Run ───────────────────────────────────────────────────────────────────────
echo "==========================================="
echo " NCP Reconciler Unit Tests"
echo "==========================================="

test_reconciler_healthy_via_explicit_checks
test_reconciler_drifted_via_explicit_checks
test_reconciler_declarative_healthy
test_reconciler_declarative_drifted
test_reconciler_declarative_hash_mismatch
test_reconciler_fallback_healthy
test_reconciler_fallback_drifted

# Clean up mock provider
rm -f "$MOCK_PROVIDER"

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count test(s) failed."
    exit 1
fi

success "All reconciler tests passed!"
