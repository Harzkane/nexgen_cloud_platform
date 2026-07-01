# Module: uptime

Category: `monitoring`

---

## Overview

NCP module for `uptime`. Follows the NCP Unified Module Standard (ADR 0002).

## Lifecycle Hooks

| Hook | Script | Description |
|------|--------|-------------|
| install | `install.sh` | Install the module |
| verify | `verify.sh` | Verify installation success |
| status | `status.sh` | Query runtime status |
| configure | `configure.sh` | Apply configuration |
| upgrade | `upgrade.sh` | Upgrade to latest version |
| uninstall | `uninstall.sh` | Remove the module |
