#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Logger Engine
# ============================================================

set -euo pipefail

# Log directory is set by context or defaults to workspace/logs
NCP_LOG_DIR="${NCP_LOG_DIR:-}"

# ANSI colour codes (only when outputting to a terminal)
_ncp_colors_enabled() {
    [ -t 1 ] && return 0 || return 1
}

_c_reset="\033[0m"
_c_bold="\033[1m"
_c_info="\033[34m"     # blue
_c_success="\033[32m"  # green
_c_warn="\033[33m"     # yellow
_c_error="\033[31m"    # red
_c_dim="\033[2m"       # dim

_log_colored() {
    local color="$1"
    local label="$2"
    local msg="$3"
    local log_file="${4:-}"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local plain_line="[$timestamp] [$label] $msg"

    if _ncp_colors_enabled; then
        printf "${color}${_c_bold}[%-7s]${_c_reset} ${_c_dim}%s${_c_reset}  %s\n" \
            "$label" "$timestamp" "$msg"
    else
        echo "$plain_line"
    fi

    # Write to log file if set
    if [ -n "$log_file" ]; then
        echo "$plain_line" >> "$log_file"
    elif [ -n "${NCP_LOG_DIR:-}" ] && [ -d "${NCP_LOG_DIR:-}" ]; then
        echo "$plain_line" >> "${NCP_LOG_DIR:-}/ncp.log"
    fi
}

log_info() {
    _log_colored "$_c_info" "INFO" "$1" "${2:-}"
}

log_success() {
    _log_colored "$_c_success" "SUCCESS" "$1" "${2:-}"
}

log_warning() {
    _log_colored "$_c_warn" "WARNING" "$1" "${2:-}"
}

log_error() {
    _log_colored "$_c_error" "ERROR" "$1" "${2:-}" >&2
}

log_step() {
    local label="$1"
    local msg="$2"
    local log_file="${3:-}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local plain_line="[$timestamp] [STEP] [$label] $msg"

    if _ncp_colors_enabled; then
        printf "\n${_c_bold}  ▶ %-20s${_c_reset}  %s\n" "$label" "$msg"
    else
        echo "$plain_line"
    fi

    if [ -n "$log_file" ]; then
        echo "$plain_line" >> "$log_file"
    elif [ -n "${NCP_LOG_DIR:-}" ] && [ -d "${NCP_LOG_DIR:-}" ]; then
        echo "$plain_line" >> "${NCP_LOG_DIR:-}/ncp.log"
    fi
}

# Write a section header separator
log_section() {
    local title="$1"
    if _ncp_colors_enabled; then
        printf "\n${_c_bold}${_c_info}=== %s ===${_c_reset}\n\n" "$title"
    else
        echo ""
        echo "=== $title ==="
        echo ""
    fi
}

# Structured lifecycle result block — shown when a lifecycle hook completes (pass or fail).
# Usage: log_lifecycle_result <component_id> <hook_name> <exit_code> <duration_secs> <log_file>
log_lifecycle_result() {
    local comp_id="$1"
    local hook_name="$2"
    local exit_code="$3"
    local duration="$4"
    local log_file="${5:-}"

    local status_label status_color
    if [ "$exit_code" -eq 0 ]; then
        status_label="SUCCESS"
        status_color="$_c_success"
    elif [ "$exit_code" -eq 124 ]; then
        status_label="TIMEOUT"
        status_color="$_c_warn"
    else
        status_label="FAILED"
        status_color="$_c_error"
    fi

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if _ncp_colors_enabled; then
        printf "\n${_c_bold}  ┌─ Lifecycle Result ──────────────────────────${_c_reset}\n"
        printf "  ${_c_dim}│${_c_reset}  %-12s %s\n" "Component :" "$comp_id"
        printf "  ${_c_dim}│${_c_reset}  %-12s %s\n" "Lifecycle :" "$hook_name"
        printf "  ${_c_dim}│${_c_reset}  %-12s ${status_color}${_c_bold}%s (%s)${_c_reset}\n" "Status    :" "$status_label" "$exit_code"
        printf "  ${_c_dim}│${_c_reset}  %-12s %ss\n" "Duration  :" "$duration"
        [ -n "$log_file" ] && printf "  ${_c_dim}│${_c_reset}  %-12s %s\n" "Log File  :" "$log_file"
        printf "${_c_bold}  └─────────────────────────────────────────────${_c_reset}\n\n"
    else
        echo "[$timestamp] [$status_label] Component=$comp_id Lifecycle=$hook_name ExitCode=$exit_code Duration=${duration}s${log_file:+ LogFile=$log_file}"
    fi
}
