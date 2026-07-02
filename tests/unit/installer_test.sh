#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Installer / Planner Test Suite
# bash tests/installer_test.sh
# ============================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$TEST_DIR/../.."

source "$PROJECT_ROOT/core/utils/output.sh"
source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/manifest/parser.sh"
source "$PROJECT_ROOT/core/manifest/validator.sh"
source "$PROJECT_ROOT/core/manifest/loader.sh"
source "$PROJECT_ROOT/core/component/registry.sh"
source "$PROJECT_ROOT/core/component/resolver.sh"
source "$PROJECT_ROOT/core/engine/planner.sh"

FIXTURE_DIR="$PROJECT_ROOT/tests/fixtures/planner"
mkdir -p "$FIXTURE_DIR"

# ── Test helpers ──────────────────────────────────────────────────────────────

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

assert_failure() {
    local rc="$1"
    local label="$2"
    if [ "$rc" -ne 0 ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (expected failure, got exit 0)"
        fail_count=$((fail_count + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if echo "$haystack" | grep -qx "$needle"; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label (expected '$needle' in plan)"
        fail_count=$((fail_count + 1))
    fi
}

assert_order() {
    local plan="$1"
    local before="$2"
    local after="$3"
    local label="$4"
    local pos_before pos_after
    pos_before=$(echo "$plan" | grep -n "^${before}$" | cut -d: -f1 || echo "0")
    pos_after=$(echo "$plan" | grep -n "^${after}$" | cut -d: -f1 || echo "0")
    if [ "${pos_before:-0}" -lt "${pos_after:-0}" ] && [ "${pos_before:-0}" -gt 0 ] && [ "${pos_after:-0}" -gt 0 ]; then
        success "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] $label ('$before' should come before '$after' in plan)"
        fail_count=$((fail_count + 1))
    fi
}

# ── Fixture helpers ───────────────────────────────────────────────────────────

make_component() {
    local id="$1"
    local version="${2:-1.0.0}"
    local deps="${3:-}"   # space-separated dep IDs

    local dir="$FIXTURE_DIR/$id"
    mkdir -p "$dir"

    # Bash 3.2-compatible capitalisation (macOS default shell)
    local display_name
    display_name=$(echo "$id" | sed 's/\b\(.\)/\u\1/g' 2>/dev/null || echo "$id")

    local dep_block=""
    if [ -n "$deps" ]; then
        dep_block="dependencies:"
        for dep_id in $deps; do
            dep_block="${dep_block}
  - id: ${dep_id}"
        done
    fi

    {
        echo "apiVersion: ncp.io/v1"
        echo "kind: Module"
        echo "id: $id"
        echo "name: $id"
        echo "displayName: $display_name"
        echo "version: $version"
        echo "category: test"
        if [ -n "$dep_block" ]; then
            echo "$dep_block"
        fi
    } > "$dir/manifest.yml"
}

# ── Test suites ───────────────────────────────────────────────────────────────

test_planner_basic() {
    echo "Running planner basic tests..."

    # Reset registry
    NCP_REGISTRY_COMPONENTS=""

    # Create fixtures: alpha has no deps, beta depends on alpha
    make_component "alpha" "1.0.0" ""
    make_component "beta"  "1.0.0" "alpha"

    # Register both
    register_component "$FIXTURE_DIR/alpha" >/dev/null
    register_component "$FIXTURE_DIR/beta"  >/dev/null

    # Build a plan for beta — should include alpha first
    local plan=""
    local rc=0
    plan=$(build_plan "beta") || rc=$?
    assert_success $rc "build_plan succeeds for known component"
    assert_contains "$plan" "alpha" "Plan includes transitive dependency (alpha)"
    assert_contains "$plan" "beta"  "Plan includes requested component (beta)"
    assert_order "$plan" "alpha" "beta" "alpha comes before beta in plan"
}

test_planner_deduplication() {
    echo "Running planner deduplication tests..."

    NCP_REGISTRY_COMPONENTS=""

    make_component "shared" "1.0.0" ""
    make_component "comp-a" "1.0.0" "shared"
    make_component "comp-b" "1.0.0" "shared"

    register_component "$FIXTURE_DIR/shared" >/dev/null
    register_component "$FIXTURE_DIR/comp-a" >/dev/null
    register_component "$FIXTURE_DIR/comp-b" >/dev/null

    # Request both comp-a and comp-b — shared should appear only once
    local plan=""
    plan=$(build_plan "comp-a" "comp-b")

    local shared_count
    shared_count=$(echo "$plan" | grep -c "^shared$" || true)
    if [ "$shared_count" -eq 1 ]; then
        success "  [PASS] Shared dependency appears exactly once (deduplication)"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] Shared dependency appeared $shared_count times (expected 1)"
        fail_count=$((fail_count + 1))
    fi
}

test_planner_unknown_component() {
    echo "Running planner unknown component tests..."

    NCP_REGISTRY_COMPONENTS=""

    # Requesting a component that isn't registered should fail
    local rc=0
    build_plan "does-not-exist" >/dev/null 2>&1 || rc=$?
    assert_failure $rc "build_plan fails for unknown component"
}

test_planner_multi_target() {
    echo "Running planner multi-target tests..."

    NCP_REGISTRY_COMPONENTS=""

    make_component "base"    "1.0.0" ""
    make_component "web"     "1.0.0" "base"
    make_component "db"      "1.0.0" "base"

    register_component "$FIXTURE_DIR/base" >/dev/null
    register_component "$FIXTURE_DIR/web"  >/dev/null
    register_component "$FIXTURE_DIR/db"   >/dev/null

    # Request both web and db — base should be first and appear once
    local plan=""
    plan=$(build_plan "web" "db")

    assert_contains "$plan" "base" "Multi-target plan includes shared base dep"
    assert_contains "$plan" "web"  "Multi-target plan includes web"
    assert_contains "$plan" "db"   "Multi-target plan includes db"
    assert_order "$plan" "base" "web" "base before web in multi-target plan"
    assert_order "$plan" "base" "db"  "base before db in multi-target plan"

    local base_count
    base_count=$(echo "$plan" | grep -c "^base$" || true)
    if [ "$base_count" -eq 1 ]; then
        success "  [PASS] base appears exactly once across multi-target plan"
        pass_count=$((pass_count + 1))
    else
        error "  [FAIL] base appeared $base_count times in multi-target plan (expected 1)"
        fail_count=$((fail_count + 1))
    fi
}

# ── Run ───────────────────────────────────────────────────────────────────────

echo "==========================================="
echo " NCP Installer / Planner Test Suite"
echo "==========================================="

test_planner_basic
test_planner_deduplication
test_planner_unknown_component
test_planner_multi_target

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed"

if [ "$fail_count" -gt 0 ]; then
    error "$fail_count test(s) failed."
    exit 1
fi

success "All installer/planner tests passed!"
