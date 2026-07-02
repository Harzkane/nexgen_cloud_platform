#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Unit Test: Resource Planner Engine
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

source "$PROJECT_ROOT/core/utils/output.sh"

# Create mockplan provider to return simulated diff results
MOCK_PROVIDER="${PROJECT_ROOT}/core/resources/mockplan.sh"

cat << 'EOF' > "$MOCK_PROVIDER"
#!/usr/bin/env bash
resource_mockplan_state() {
    echo "present"
}
resource_mockplan_diff() {
    local target="$1"
    case "$target" in
        satisfied-res) echo "SATISFIED" ;;
        missing-res)   echo "MISSING"   ;;
        drifted-res)   echo "DRIFTED"   ;;
        *)             echo "MISSING"   ;;
    esac
}
EOF

source "$PROJECT_ROOT/core/engine/resource_planner.sh"

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

assert_file_contains() {
    local content="$1"
    local pattern="$2"
    local label="$3"
    if echo "$content" | grep -qF -- "$pattern"; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (pattern '$pattern' not found in '$content')"
        fail_count=$((fail_count + 1))
    fi
}

# Stub registry checks
is_component_registered() {
    return 0
}

test_resource_plan_generation() {
    echo "Running unit: resource plan generation actions..."

    # Setup component manifest vars
    export NCP_COMP_test_plan_resources_count=3
    
    export NCP_COMP_test_plan_resources_0_type="mockplan"
    export NCP_COMP_test_plan_resources_0_name="satisfied-res"
    export NCP_COMP_test_plan_resources_0_state="present"

    export NCP_COMP_test_plan_resources_1_type="mockplan"
    export NCP_COMP_test_plan_resources_1_name="missing-res"
    export NCP_COMP_test_plan_resources_1_state="present"

    export NCP_COMP_test_plan_resources_2_type="mockplan"
    export NCP_COMP_test_plan_resources_2_name="drifted-res"
    export NCP_COMP_test_plan_resources_2_state="present"

    local out
    out=$(expand_component_resources "test-plan")

    # Satisfied resource should result in NOOP with auto ID satisfied-res-mockplan
    assert_file_contains "$out" "NOOP|mockplan|satisfied-res|present|satisfied-res-mockplan" "Satisfied resource maps to NOOP and auto-generates ID"

    # Missing resource should result in CREATE
    assert_file_contains "$out" "CREATE|mockplan|missing-res|present|missing-res-mockplan" "Missing resource maps to CREATE"

    # Drifted resource should result in UPDATE
    assert_file_contains "$out" "UPDATE|mockplan|drifted-res|present|drifted-res-mockplan" "Drifted resource maps to UPDATE"
}

echo "==========================================="
echo " NCP Resource Planner Unit Tests"
echo "==========================================="

test_resource_plan_generation

# Clean up mock provider
rm -f "$MOCK_PROVIDER"

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count test(s) failed."
    exit 1
fi

success "All resource planner tests passed!"
