#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Transactional Rollback Engine
# ============================================================
# Rollback ONLY undoes resources that belong to components
# installed during the current execution session (installed_this_run).
# Components that were already present before the operation started
# (already_present) are NEVER touched.
# ============================================================

set -euo pipefail

ROLLBACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$ROLLBACK_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"
source "$PROJECT_ROOT/core/platform/packages.sh"
source "$PROJECT_ROOT/core/platform/services.sh"
source "$PROJECT_ROOT/core/state/state.sh"
source "$PROJECT_ROOT/core/state/transactions.sh"
source "$PROJECT_ROOT/core/engine/events.sh"

# ---------------------------------------------------------------------------
# _parse_section <txn_file> <section_header>
# Echoes all non-empty lines between <section_header> and the next sentinel.
# ---------------------------------------------------------------------------
_parse_section() {
    local txn_file="$1"
    local header="$2"
    local in_section=false

    while IFS= read -r line; do
        if [ "$line" = "$header" ]; then
            in_section=true
            continue
        fi
        if [[ "$line" == "--- "* ]] && [ "$in_section" = "true" ]; then
            break
        fi
        [ "$in_section" = "true" ] && [ -n "$line" ] && echo "$line"
    done < "$txn_file"
}

# ---------------------------------------------------------------------------
# rollback_transaction <txn_id>
#
# Reads the transaction file for txn_id and reverses only the resource
# mutations that belong to components installed during that run.
# Pre-existing components are skipped entirely.
# ---------------------------------------------------------------------------
rollback_transaction() {
    local txn_id="$1"
    local txn_store="${NCP_TXN_STORE_DIR:-${PROJECT_ROOT}/workspace/transactions}"
    local txn_file="${txn_store}/txn-${txn_id}.state"

    if [ ! -f "$txn_file" ]; then
        log_error "Transaction file not found: $txn_file"
        return 1
    fi

    publish_event "operation:rollback:before" "$txn_id"
    log_section "Rolling Back Transaction: txn-$txn_id"

    # ── 1. Load the installed_this_run set ───────────────────────────────
    local -a installed_this_run=()
    local comp_id
    while IFS= read -r comp_id; do
        installed_this_run+=("$comp_id")
    done < <(_parse_section "$txn_file" "--- COMPONENTS_INSTALLED_THIS_RUN ---")

    if [ "${#installed_this_run[@]}" -eq 0 ]; then
        log_info "No components were installed by this transaction. Nothing to roll back."
        publish_event "operation:rollback:after" "$txn_id" "NOOP"
        return 0
    fi

    log_info "Components installed this run (eligible for rollback): ${installed_this_run[*]}"

    # ── 2. Load resource mutations ───────────────────────────────────────
    local -a all_items=()
    while IFS= read -r line; do
        [ -n "$line" ] && all_items+=("$line")
    done < <(_parse_section "$txn_file" "--- RESOURCES ---")

    # ── 3. Build membership string for installed_this_run (bash 3.2 compat) ────
    local run_set_str=""
    for comp_id in "${installed_this_run[@]}"; do
        run_set_str="${run_set_str}${comp_id}
"
    done

    # ── 4. Reverse mutations — only for components in run_set ────────────
    local len=${#all_items[@]}
    log_info "Scanning $len resource mutation(s) for rollback candidates..."

    # Log rollback start to session if active
    if declare -f log_session_rollback > /dev/null 2>&1; then
        log_session_rollback "Rollback started for txn-$txn_id"
        log_session_rollback "Eligible components: ${installed_this_run[*]}"
    fi

    for ((i=len-1; i>=0; i--)); do
        local item="${all_items[i]}"
        # Format: res_type|target|meta|comp_id
        local res_type target meta item_comp_id
        res_type=$(echo "$item" | cut -d'|' -f1)
        target=$(echo "$item" | cut -d'|' -f2)
        meta=$(echo "$item" | cut -d'|' -f3 || echo "")
        item_comp_id=$(echo "$item" | cut -d'|' -f4 || echo "")

        # Skip resources that belong to pre-existing components (bash 3.2 compat grep check)
        if [ -n "$item_comp_id" ] && ! echo "$run_set_str" | grep -qxF "$item_comp_id"; then
            log_info "Skipping rollback of '$res_type:$target' — component '$item_comp_id' was already present."
            continue
        fi

        log_info "Reversing resource '$res_type:$target' (component: ${item_comp_id:-unknown})..."

        if declare -f log_session_rollback > /dev/null 2>&1; then
            log_session_rollback "Reversing $res_type:$target (comp: ${item_comp_id:-unknown})"
        fi

        publish_event "component:rollback" "${item_comp_id:-$txn_id}" "$res_type:$target"

        case "$res_type" in
            package)
                uninstall_package "$target" || true
                ;;
            directory)
                rm -rf "$target" 2>/dev/null || sudo rm -rf "$target" || true
                ;;
            file)
                rm -f "$target" 2>/dev/null || sudo rm -f "$target" || true
                ;;
            symlink)
                rm -f "$target" 2>/dev/null || sudo rm -f "$target" || true
                ;;
            service)
                if [ "$meta" = "started" ]; then
                    stop_service "$target" || true
                fi
                ;;
            user)
                local os
                os=$(uname -s)
                if [ "$os" = "Darwin" ]; then
                    sudo sysadminctl -deleteUser "$target" > /dev/null 2>&1 || true
                else
                    sudo userdel -r "$target" > /dev/null 2>&1 || true
                fi
                ;;
            group)
                local os
                os=$(uname -s)
                if [ "$os" = "Darwin" ]; then
                    sudo dscl . -delete "/Groups/$target" > /dev/null 2>&1 || true
                else
                    sudo groupdel "$target" > /dev/null 2>&1 || true
                fi
                ;;
            *)
                log_warning "Unknown resource type '$res_type' in transaction. Skipping."
                ;;
        esac
    done

    # ── 5. Mark components as ROLLED_BACK ───────────────────────────────
    for comp_id in "${installed_this_run[@]}"; do
        mark_rolled_back "$comp_id" 2>/dev/null || true
    done

    # ── 6. Update transaction status ────────────────────────────────────
    local temp_f
    temp_f=$(mktemp)
    sed 's/^status=.*/status=ROLLED_BACK/' "$txn_file" > "$temp_f"
    mv "$temp_f" "$txn_file"

    if declare -f log_session_rollback > /dev/null 2>&1; then
        log_session_rollback "Rollback completed for txn-$txn_id"
    fi

    publish_event "operation:rollback:after" "$txn_id" "ROLLED_BACK"
    log_success "Rollback of transaction txn-$txn_id completed."
    return 0
}
