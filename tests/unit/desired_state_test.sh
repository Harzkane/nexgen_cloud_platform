#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Unit Test: Desired-State Loader
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

source "$PROJECT_ROOT/core/utils/output.sh"
source "$PROJECT_ROOT/core/engine/desired_state/loader.sh"

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

# Stub is_component_registered so registry.sh doesn't complain about test-comp
is_component_registered() {
    return 0
}

test_desired_state_detection() {
    echo "Running unit: has_desired_resources detection..."

    # Setup mock parsed vars
    export NCP_COMP_test_comp_resources_count=1
    export NCP_COMP_test_comp_resources_0_type="package"

    local has_res=1
    has_desired_resources "test-comp" && has_res=0 || has_res=1
    assert_equals 0 "$has_res" "Component with resource count > 0 returns true"

    # Count = 0
    export NCP_COMP_no_res_comp_resources_count=0
    local has_res2=1
    has_desired_resources "no-res-comp" && has_res2=0 || has_res2=1
    assert_equals 1 "$has_res2" "Component with resource count = 0 returns false"
}

test_desired_state_loader() {
    echo "Running unit: load_desired_resources normalization..."

    # Setup mock package resource
    export NCP_COMP_test_loader_resources_count=3
    export NCP_COMP_test_loader_resources_0_type="package"
    export NCP_COMP_test_loader_resources_0_name="curl"
    export NCP_COMP_test_loader_resources_0_state="present"

    # Setup mock directory resource
    export NCP_COMP_test_loader_resources_1_type="directory"
    export NCP_COMP_test_loader_resources_1_path="/var/log/ncp"
    export NCP_COMP_test_loader_resources_1_owner="admin"
    export NCP_COMP_test_loader_resources_1_group="wheel"
    export NCP_COMP_test_loader_resources_1_mode="0777"
    export NCP_COMP_test_loader_resources_1_state="present"

    # Setup mock file resource
    export NCP_COMP_test_loader_resources_2_type="file"
    export NCP_COMP_test_loader_resources_2_path="/etc/ncp.conf"
    export NCP_COMP_test_loader_resources_2_content="enabled=true"
    export NCP_COMP_test_loader_resources_2_owner="root"
    export NCP_COMP_test_loader_resources_2_group="root"
    export NCP_COMP_test_loader_resources_2_mode="0644"
    export NCP_COMP_test_loader_resources_2_state="present"

    local out
    out=$(load_desired_resources "test-loader")

    # Verify package normalization
    assert_file_contains "$out" "curl-package|package|curl|present" "Package normalized correctly"

    # Verify directory normalization
    assert_file_contains "$out" "-var-log-ncp-directory|directory|/var/log/ncp|present|admin|wheel|0777" "Directory normalized correctly"

    # Verify file normalization
    assert_file_contains "$out" "-etc-ncp-conf-file|file|/etc/ncp.conf|present|enabled=true|root|root|0644" "File normalized correctly"

    # Verify hash compilation works and is non-empty
    local hash
    hash=$(compute_desired_state_hash "test-loader")
    if [ -n "$hash" ]; then
        success "  [PASS] Hash computed: $hash"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] Failed to compute desired-state hash"
        fail_count=$((fail_count + 1))
    fi
}

echo "==========================================="
echo " NCP Desired-State Loader Unit Tests"
echo "==========================================="

test_desired_state_detection
test_desired_state_loader

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count test(s) failed."
    exit 1
fi

success "All desired state loader tests passed!"
