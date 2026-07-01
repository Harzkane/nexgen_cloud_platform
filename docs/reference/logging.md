# NCP Logging Reference

---

## Overview

NCP uses a consistent, structured logging standard across all CLI commands, module lifecycle scripts, and Core Engine operations.

Structured logging makes output human-readable in the terminal and machine-parseable in CI/CD pipelines or monitoring systems.

---

## Log Levels

NCP defines four log levels, each represented by a prefix label:

| Level | Label | Purpose |
|-------|-------|---------|
| Info | `[INFO]` | General progress messages |
| Success | `[SUCCESS]` | Confirmation of a completed operation |
| Warning | `[WARNING]` | Non-fatal issues that require attention |
| Error | `[ERROR]` | Fatal failures that stop execution |

---

## Output Functions

All scripts must source the shared output utility before logging:

```bash
source "$PROJECT_ROOT/core/utils/output.sh"
```

### Available Functions

```bash
info "Checking system requirements..."
# Output: [INFO] Checking system requirements...

success "Docker installed successfully."
# Output: [SUCCESS] Docker installed successfully.

warning "Swap is not configured. Performance may be affected."
# Output: [WARNING] Swap is not configured. Performance may be affected.

error "Installation failed. Unsupported OS."
# Output: [ERROR] Installation failed. Unsupported OS.
```

---

## Implementation (`core/utils/output.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

info() {
    echo "[INFO] $1"
}

success() {
    echo "[SUCCESS] $1"
}

warning() {
    echo "[WARNING] $1"
}

error() {
    echo "[ERROR] $1"
}
```

---

## Logging Rules

### Rule 1 — Never use raw `echo` for status messages

✅ Correct:
```bash
info "Installing Docker..."
```

❌ Incorrect:
```bash
echo "Installing Docker..."
```

### Rule 2 — Always log before and after long operations

```bash
info "Downloading Docker packages..."
apt-get install -y docker-ce docker-ce-cli containerd.io
success "Docker packages installed."
```

### Rule 3 — Always log before exit on failure

```bash
if ! command -v docker &>/dev/null; then
    error "Docker binary not found after installation."
    exit 40
fi
```

### Rule 4 — Warnings must not exit non-zero

```bash
if [ "$SWAP_SIZE" -lt 1024 ]; then
    warning "Swap is less than 1GB. Recommended: 2GB."
    # Continue — do not exit 1
fi
```

---

## Future: Log Files

In a future milestone, NCP will write structured logs to disk.

Planned log path:

```
workspace/
└── logs/
    ├── ncp.log         — Combined NCP activity log
    ├── install.log     — Installation operation logs
    └── error.log       — Error-only log stream
```

Log file format will follow:

```
[2026-07-01 12:00:00] [INFO] [docker] Installing Docker Engine...
[2026-07-01 12:00:45] [SUCCESS] [docker] Docker Engine installed. Version: 27.0.3
```
