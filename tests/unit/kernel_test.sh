#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Automated Kernel Smoke Test Suite
# bash tests/kernel_test.sh
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

# Source the kernel files
source "$PROJECT_ROOT/core/utils/output.sh"
source "$PROJECT_ROOT/core/manifest/parser.sh"
source "$PROJECT_ROOT/core/manifest/validator.sh"
source "$PROJECT_ROOT/core/manifest/loader.sh"
source "$PROJECT_ROOT/core/component/resolver.sh"
source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/engine/executor.sh"

# Set up fixtures directory
FIXTURE_DIR="$PROJECT_ROOT/tests/fixtures/smoke"
rm -rf "$FIXTURE_DIR"
mkdir -p "$FIXTURE_DIR"

cleanup() {
    rm -rf "$FIXTURE_DIR"
}
trap cleanup EXIT

# Test helper functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="$3"
    if [ "$expected" != "$actual" ]; then
        echo "  [FAIL] $msg (Expected: '$expected', Actual: '$actual')" >&2
        return 1
    fi
    return 0
}

assert_success() {
    local exit_code="$1"
    local msg="$2"
    if [ "$exit_code" -ne 0 ]; then
        echo "  [FAIL] $msg (Expected success, got exit code $exit_code)" >&2
        return 1
    fi
    return 0
}

assert_failure() {
    local exit_code="$1"
    local msg="$2"
    if [ "$exit_code" -eq 0 ]; then
        echo "  [FAIL] $msg (Expected failure, got exit code 0)" >&2
        return 1
    fi
    return 0
}

# --- TEST CASES ---

test_manifest_parser() {
    echo "Running parser tests..."
    
    # Create a test manifest
    local test_manifest="$FIXTURE_DIR/test_manifest.yml"
    cat <<EOF > "$test_manifest"
apiVersion: ncp.io/v1
kind: Module
id: test-comp
name: test-comp
displayName: Test Component
version: 1.2.3
category: system
description: >
  Line 1
  Line 2
dependencies:
  - id: git
    version: ">=1.0"
  - id: curl
compatibility:
  ubuntu:
    - "22.04"
EOF

    clear_manifest_variables "TEST_P_"
    parse_manifest "$test_manifest" "TEST_P_"

    assert_equals "ncp.io/v1" "$TEST_P_apiVersion" "Parse apiVersion"
    assert_equals "Module" "$TEST_P_kind" "Parse kind"
    assert_equals "test-comp" "$TEST_P_id" "Parse id"
    assert_equals "Test Component" "$TEST_P_displayName" "Parse displayName"
    assert_equals "1.2.3" "$TEST_P_version" "Parse version"
    assert_equals "system" "$TEST_P_category" "Parse category"
    assert_equals "Line 1 Line 2" "$TEST_P_description" "Parse folded multi-line string"
    assert_equals "2" "$TEST_P_dependencies_count" "Parse dependencies count"
    assert_equals "git" "$TEST_P_dependencies_0_id" "Parse dependency 0 ID"
    assert_equals ">=1.0" "$TEST_P_dependencies_0_version" "Parse dependency 0 version"
    assert_equals "curl" "$TEST_P_dependencies_1_id" "Parse dependency 1 ID"
    assert_equals "1" "$TEST_P_compatibility_ubuntu_count" "Parse compatibility list count"
    assert_equals "22.04" "$TEST_P_compatibility_ubuntu_0" "Parse compatibility list value"
}

test_manifest_validator() {
    echo "Running validator tests..."
    
    # Test valid manifest (with mock script files)
    local valid_dir="$FIXTURE_DIR/valid_comp"
    mkdir -p "$valid_dir"
    touch "$valid_dir/install.sh" "$valid_dir/verify.sh"
    
    local manifest="$valid_dir/manifest.yml"
    cat <<EOF > "$manifest"
apiVersion: ncp.io/v1
kind: Module
id: valid-comp
name: valid-comp
displayName: Valid Component
version: 1.0.0
category: databases
lifecycle:
  install:
    script: install.sh
  verify:
    script: verify.sh
EOF

    validate_manifest "$manifest"
    assert_success $? "Validate well-formed manifest"

    # Test invalid manifest (missing required fields)
    local invalid_manifest="$FIXTURE_DIR/invalid_manifest.yml"
    cat <<EOF > "$invalid_manifest"
apiVersion: ncp.io/v1
kind: Module
id: incomplete-comp
# Missing version and category
EOF

    local rc_incomplete=0
    validate_manifest "$invalid_manifest" >/dev/null 2>&1 || rc_incomplete=$?
    assert_failure $rc_incomplete "Validate manifest with missing required fields"

    # Test invalid manifest (references non-existent script)
    local bad_script_dir="$FIXTURE_DIR/bad_script_comp"
    mkdir -p "$bad_script_dir"
    local bad_manifest="$bad_script_dir/manifest.yml"
    cat <<EOF > "$bad_manifest"
apiVersion: ncp.io/v1
kind: Module
id: bad-script
name: bad-script
displayName: Bad Script Component
version: 1.0.0
category: system
lifecycle:
  install:
    script: missing_install.sh
EOF

    local rc_bad_script=0
    validate_manifest "$bad_manifest" >/dev/null 2>&1 || rc_bad_script=$?
    assert_failure $rc_bad_script "Validate manifest referencing missing script"
}

test_component_registry() {
    echo "Running registry tests..."
    
    local comp_dir="$FIXTURE_DIR/reg_comp"
    mkdir -p "$comp_dir"
    local manifest="$comp_dir/manifest.yml"
    cat <<EOF > "$manifest"
apiVersion: ncp.io/v1
kind: Module
id: reg-comp
name: reg-comp
displayName: Registry Component
version: 2.1.0
category: security
EOF

    # Reset registry state for test isolation
    NCP_REGISTRY_COMPONENTS=""

    register_component "$comp_dir" >/dev/null
    assert_success $? "Register component"

    assert_equals "reg-comp" "$(get_registered_components)" "Retrieve registered IDs"
    assert_equals "Registry Component" "$(get_component_property "reg-comp" "displayName")" "Get registered property"
    assert_equals "2.1.0" "$(get_component_property "reg-comp" "version")" "Get registered version"
}

test_dependency_resolver() {
    echo "Running resolver tests..."
    
    # Reset registry state for test isolation
    NCP_REGISTRY_COMPONENTS=""

    # Register multiple components for dependency graph
    # comp-a depends on comp-b
    # comp-b depends on comp-c
    # comp-c has no dependencies
    
    local i
    for i in a b c; do
        local dir="$FIXTURE_DIR/comp-$i"
        mkdir -p "$dir"
        local manifest="$dir/manifest.yml"
        
        local deps=""
        if [ "$i" = "a" ]; then
            deps="  - id: comp-b"
        elif [ "$i" = "b" ]; then
            deps="  - id: comp-c"
        fi
        
        cat <<EOF > "$manifest"
apiVersion: ncp.io/v1
kind: Module
id: comp-$i
name: comp-$i
displayName: Component $i
version: 1.0.0
category: test
dependencies:
$deps
EOF
        register_component "$dir" >/dev/null
    done

    local order
    order=$(resolve_dependencies "comp-a")
    assert_success $? "Resolve acyclic dependencies"
    assert_equals "comp-c comp-b comp-a" "$order" "Verify topological sort order"

    # Test circular dependency detection
    # Modify comp-c to depend on comp-a
    local dir_c="$FIXTURE_DIR/comp-c"
    cat <<EOF > "$dir_c/manifest.yml"
apiVersion: ncp.io/v1
kind: Module
id: comp-c
name: comp-c
displayName: Component C
version: 1.0.0
category: test
dependencies:
  - id: comp-a
EOF
    # Reload comp-c
    register_component "$dir_c" >/dev/null
    
    local rc_circular=0
    resolve_dependencies "comp-a" >/dev/null 2>&1 || rc_circular=$?
    assert_failure $rc_circular "Detect circular dependencies"
}

test_executor() {
    echo "Running executor tests..."

    # Test successful script execution
    local success_script="$FIXTURE_DIR/ok.sh"
    echo '#!/usr/bin/env bash' > "$success_script"
    echo 'exit 0' >> "$success_script"
    chmod +x "$success_script"

    local rc_ok=0
    execute_script "$success_script" 10 false "" || rc_ok=$?
    assert_success $rc_ok "Executor runs script successfully"

    # Test failing script
    local fail_script="$FIXTURE_DIR/fail.sh"
    echo '#!/usr/bin/env bash' > "$fail_script"
    echo 'exit 42' >> "$fail_script"
    chmod +x "$fail_script"

    local rc_fail=0
    execute_script "$fail_script" 10 false "" || rc_fail=$?
    assert_failure $rc_fail "Executor propagates non-zero exit code"

    # Test timeout — script sleeps longer than the timeout
    local slow_script="$FIXTURE_DIR/slow.sh"
    echo '#!/usr/bin/env bash' > "$slow_script"
    echo 'sleep 60' >> "$slow_script"
    chmod +x "$slow_script"

    local rc_timeout=0
    execute_script "$slow_script" 2 false "" >/dev/null 2>&1 || rc_timeout=$?
    assert_equals "124" "$rc_timeout" "Executor kills timed-out script (exit 124)"

    # Test log file output capture
    local log_script="$FIXTURE_DIR/log_me.sh"
    echo '#!/usr/bin/env bash' > "$log_script"
    echo 'echo HELLO_FROM_SCRIPT' >> "$log_script"
    chmod +x "$log_script"

    local log_out="$FIXTURE_DIR/test_exec.log"
    execute_script "$log_script" 10 false "$log_out" >/dev/null
    local log_content
    log_content=$(cat "$log_out" 2>/dev/null || echo "")
    if echo "$log_content" | grep -q "HELLO_FROM_SCRIPT"; then
        : # pass
    else
        echo "  [FAIL] Executor captures output to log file" >&2
        return 1
    fi
}

test_context() {
    echo "Running context tests..."

    # Set up a minimal registered component
    NCP_REGISTRY_COMPONENTS=""
    local dir="$FIXTURE_DIR/ctx-comp"
    mkdir -p "$dir"
    cat <<EOF > "$dir/manifest.yml"
apiVersion: ncp.io/v1
kind: Module
id: ctx-comp
name: ctx-comp
displayName: Context Component
version: 3.0.0
category: system
EOF
    register_component "$dir" >/dev/null

    # Source context after registry is populated
    source "$PROJECT_ROOT/core/engine/context.sh"
    init_context "ctx-comp"

    assert_equals "ctx-comp" "${NCP_COMPONENT_ID:-}" "Context exports NCP_COMPONENT_ID"
    assert_equals "3.0.0" "${NCP_COMPONENT_VERSION:-}" "Context exports NCP_COMPONENT_VERSION"
    assert_equals "Context Component" "${NCP_COMPONENT_DISPLAY_NAME:-}" "Context exports NCP_COMPONENT_DISPLAY_NAME"

    [ -d "${NCP_LOG_DIR:-}" ] || { echo "  [FAIL] Context creates NCP_LOG_DIR" >&2; return 1; }
    [ -d "${NCP_TEMP_DIR:-}" ] || { echo "  [FAIL] Context creates NCP_TEMP_DIR" >&2; return 1; }

    clear_context
    assert_equals "" "${NCP_COMPONENT_ID:-}" "clear_context unsets NCP_COMPONENT_ID"
}

# --- RUN TESTS ---

echo "==========================================="
echo " Starting NCP Kernel Smoke Test Suite"
echo "==========================================="

test_manifest_parser
test_manifest_validator
test_component_registry
test_dependency_resolver
test_executor
test_context

echo
success "All smoke tests passed successfully!"
