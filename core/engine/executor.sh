#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Script Executor Engine
# ============================================================

set -euo pipefail

EXECUTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$EXECUTOR_DIR/../.." && pwd)"

source "$PROJECT_ROOT/core/logger/logger.sh"

# ── Sudo Keep-Alive ──────────────────────────────────────────────────────────
#
# Call this once before any sudo-requiring operations. It will:
# 1. Prompt the user for their password (only once).
# 2. Spawn a background loop that refreshes sudo credentials every 60 s.
# 3. Register a trap to kill the loop on exit.
#
# Usage: sudo_keepalive_start
_NCP_SUDO_PID=""

sudo_keepalive_start() {
    # Validate credentials now (prompts if not cached)
    if ! sudo -v; then
        log_error "sudo authentication failed. Cannot proceed with privileged operations."
        return 1
    fi

    # Spawn background keep-alive loop
    (
        while true; do
            sudo -n true 2>/dev/null || break
            sleep 60
        done
    ) &
    _NCP_SUDO_PID=$!

    # Kill keep-alive on exit
    trap 'sudo_keepalive_stop' EXIT INT TERM
}

sudo_keepalive_stop() {
    if [ -n "$_NCP_SUDO_PID" ] && kill -0 "$_NCP_SUDO_PID" 2>/dev/null; then
        kill "$_NCP_SUDO_PID" 2>/dev/null || true
    fi
    _NCP_SUDO_PID=""
}

# ── Timeout Runner ───────────────────────────────────────────────────────────
#
# Pure-Bash timeout implementation compatible with macOS bash 3.2.
# Runs <command...> and kills it after <timeout_seconds>, returning exit code 124.
#
# Usage: run_with_timeout <timeout_seconds> <command...>
run_with_timeout() {
    local timeout="$1"
    shift
    local cmd=("$@")

    # Run the command in a background subshell
    "${cmd[@]}" &
    local child_pid=$!

    # Spawn a background watchdog
    (
        sleep "$timeout"
        if kill -0 "$child_pid" 2>/dev/null; then
            kill -TERM "$child_pid" 2>/dev/null || true
            sleep 2
            kill -KILL "$child_pid" 2>/dev/null || true
        fi
    ) &
    local watchdog_pid=$!

    # Wait for the child process to finish
    local exit_code=0
    wait "$child_pid" 2>/dev/null || exit_code=$?

    # Kill the watchdog (it may have already exited)
    kill "$watchdog_pid" 2>/dev/null || true
    wait "$watchdog_pid" 2>/dev/null || true

    # If the child was killed by SIGTERM/SIGKILL (exit codes 128+15 or 128+9),
    # normalise to the timeout exit code 124
    if [ "$exit_code" -ge 128 ]; then
        return 124
    fi

    return "$exit_code"
}

# ── Script Runner ────────────────────────────────────────────────────────────
#
# Executes a single lifecycle script, optionally with sudo, within a timeout.
# Streams output to both the terminal and the provided log file.
#
# Usage: execute_script <script_path> <timeout_secs> <requires_sudo: true|false> <log_file>
# Returns: exit code of the script, or 124 on timeout
execute_script() {
    local script_path="$1"
    local timeout="${2:-300}"
    local requires_sudo="${3:-false}"
    local log_file="${4:-}"

    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        return 1
    fi

    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi

    # Build the command array
    local -a cmd
    if [ "$requires_sudo" = "true" ]; then
        cmd=(sudo bash "$script_path")
    else
        cmd=(bash "$script_path")
    fi

    local exit_code=0
    local start_time
    start_time=$(date +%s)

    if [ -n "$log_file" ]; then
        # Write to a temp file first so we can tee without losing the exit code
        local tmp_out
        tmp_out=$(mktemp)
        run_with_timeout "$timeout" "${cmd[@]}" > "$tmp_out" 2>&1 || exit_code=$?
        cat "$tmp_out" | tee -a "$log_file"
        rm -f "$tmp_out"
    else
        run_with_timeout "$timeout" "${cmd[@]}" || exit_code=$?
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ "$exit_code" -eq 124 ]; then
        log_error "Script timed out after ${timeout}s: $script_path"
    elif [ "$exit_code" -ne 0 ]; then
        log_error "Script exited with code $exit_code in ${duration}s: $script_path"
    else
        log_info "Script completed in ${duration}s: $(basename "$script_path")"
    fi

    return "$exit_code"
}
