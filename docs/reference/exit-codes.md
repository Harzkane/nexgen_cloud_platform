# NCP Exit Codes Reference

---

## Overview

Every NCP CLI command and every module lifecycle script must exit with a standardized exit code.

Consistent exit codes allow the Core Engine, shell scripts, CI/CD pipelines, and monitoring systems to detect failures programmatically without parsing text output.

---

## Standard Exit Codes

### 0 — Success

The operation completed successfully.

```bash
exit 0
```

### 1 — General Error

An unspecified or unexpected failure occurred.

```bash
exit 1
```

### 2 — Misuse / Invalid Usage

The command was called incorrectly (wrong arguments, unknown flags).

```bash
exit 2
```

---

## NCP-Specific Exit Codes

### 10 — Validation Failed

Pre-flight environment validation failed. The target system does not meet requirements.

```bash
exit 10
```

**Common causes:**
- Unsupported operating system
- Insufficient privileges (sudo required)
- No internet connectivity
- Missing required dependency

---

### 20 — Dependency Not Found

A required component dependency is not installed or cannot be discovered.

```bash
exit 20
```

---

### 30 — Already Installed (Idempotency)

The component is already installed in the correct state. No changes were made.

```bash
exit 30
```

> Note: This is a non-failure exit. The Core Engine treats `30` as a success equivalent for idempotent operations.

---

### 40 — Installation Failed

The install script ran but the package or service could not be configured correctly.

```bash
exit 40
```

---

### 50 — Verification Failed

The `verify.sh` hook ran but the component did not pass health checks.

```bash
exit 50
```

---

### 60 — Configuration Failed

The `configure.sh` hook failed to write configuration files or apply settings.

```bash
exit 60
```

---

### 70 — Upgrade Failed

The `upgrade.sh` hook failed to update the component version.

```bash
exit 70
```

---

### 80 — Uninstall Failed

The `uninstall.sh` hook failed to cleanly remove the component.

```bash
exit 80
```

---

### 90 — Manifest Invalid

The component's `manifest.yml` failed schema validation.

```bash
exit 90
```

---

### 99 — Internal Engine Error

An unexpected error occurred inside the NCP Core Engine itself.

```bash
exit 99
```

---

## Summary Table

| Code | Category | Meaning |
|------|----------|---------|
| `0` | Success | Operation completed successfully |
| `1` | Error | General unspecified error |
| `2` | Usage | Invalid command usage |
| `10` | Validation | Environment pre-flight check failed |
| `20` | Dependency | Required dependency missing |
| `30` | Idempotent | Already installed, no changes made |
| `40` | Install | Package installation failed |
| `50` | Verify | Health check failed |
| `60` | Configure | Configuration application failed |
| `70` | Upgrade | Version upgrade failed |
| `80` | Uninstall | Component removal failed |
| `90` | Manifest | Manifest schema validation failed |
| `99` | Engine | Internal Core Engine error |

---

## Script Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$PROJECT_ROOT/core/utils/output.sh"

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
    error "Docker binary not found after installation."
    exit 40
fi

# Check if already installed at correct version
INSTALLED_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
if [ "$INSTALLED_VERSION" = "$EXPECTED_VERSION" ]; then
    info "Docker $INSTALLED_VERSION is already installed."
    exit 30
fi

success "Docker $INSTALLED_VERSION verified."
exit 0
```
