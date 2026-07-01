# NCP Lifecycle Reference

> **Schema Version:** `ncp.io/v1`

---

## Overview

Every NCP component (Module, Provider, Template, Runtime, Service, Extension) follows a standardized lifecycle. The Core Engine uses the lifecycle declaration in a component's `manifest.yml` to discover and execute actions without hardcoded logic.

---

## Lifecycle Stages

The lifecycle consists of 8 stages executed in the following order:

```
Discover → Validate → Install → Verify → Configure → Status → Upgrade → Uninstall
```

### 1. Discover
The Core Engine scans the filesystem for component manifests. No scripts are executed at this stage.

### 2. Validate
Pre-flight environment checks before any changes are made:
- Operating system compatibility
- Required privileges (sudo)
- Internet connectivity
- Dependency availability
- Existing installation state (idempotency check)

### 3. Install
Executes the component installation script. Downloads packages, compiles binaries, or configures services.

### 4. Verify
Confirms the installation was successful by running validation checks (e.g. version assertions, service probes).

### 5. Configure
Applies configuration files, sets environment variables, and writes templates to the target system.

### 6. Status
Queries the current runtime health of the component without making changes.

### 7. Upgrade
Safely updates the component to a newer version while preserving existing configuration.

### 8. Uninstall
Removes the component, purges configuration, and restores system state.

---

## Manifest Declaration

```yaml
lifecycle:

  install:
    script: install.sh
    requiresSudo: true
    timeout: 600

  verify:
    script: verify.sh

  status:
    script: status.sh

  configure:
    script: configure.sh

  upgrade:
    script: upgrade.sh

  uninstall:
    script: uninstall.sh
```

---

## Lifecycle Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `script` | string | Yes | Relative path to the executable script |
| `requiresSudo` | boolean | No | Whether the hook requires elevated privileges (default: `false`) |
| `timeout` | integer | No | Maximum execution time in seconds (default: `300`) |

---

## Idempotency Requirement

Every lifecycle hook **must** be idempotent.

Running any hook 10 times consecutively must produce the same result as running it once. If the component is already in the desired state, the script must detect this and exit cleanly with code `0` rather than failing or re-applying changes.

---

## Script Interface Contract

Every lifecycle script must:

1. Start with `#!/usr/bin/env bash` and `set -euo pipefail`
2. Exit `0` on success
3. Exit a non-zero code on failure (see [exit-codes.md](./exit-codes.md))
4. Print structured output compatible with the NCP Logging standard (see [logging.md](./logging.md))
