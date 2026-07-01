# NCP CLI Reference

---

## Overview

The NCP CLI (`ncp`) is the single entrypoint for all NexGen Cloud Platform operations.

It provides commands for system inspection, module management, provider interaction, and application deployment.

---

## Invocation

```bash
ncp <command> [subcommand] [options]
```

---

## Global Options

| Option | Description |
|--------|-------------|
| `--help`, `-h` | Show help for a command |
| `--version`, `-v` | Show NCP version |
| `--dry-run` | Show what would happen without making changes (planned) |
| `--verbose` | Enable verbose output (planned) |
| `--quiet` | Suppress all output except errors (planned) |

---

## Core Commands

### `ncp help`

Displays the top-level help message.

```bash
ncp help
```

---

### `ncp version`

Displays the current NCP version.

```bash
ncp version
```

**Output:**
```
NexGen Cloud Platform
Version: 0.1.0-alpha
```

---

### `ncp doctor`

Inspects the current system environment and discovers all installed NCP components.

```bash
ncp doctor
```

**Output:**
```
===========================================
 NexGen Cloud Platform
 Version: 0.1.0-alpha
===========================================

[INFO] Environment
OS           : Ubuntu 24.04 LTS
Kernel       : 6.8.0-45-generic
Architecture : x86_64

[INFO] Installed Module Definitions
  ✔ Docker Engine            1.0.0
  ✔ Git                      1.0.0
  ✔ Nginx                    1.0.0

Providers    :        6
Templates    :        7

[SUCCESS] NCP Discovery completed successfully.
```

---

## Module Commands (Planned)

### `ncp module list`

Lists all discovered modules with their status.

```bash
ncp module list
```

---

### `ncp module install <name>`

Installs a specific module by its `id`.

```bash
ncp module install docker
ncp module install postgres
```

---

### `ncp module uninstall <name>`

Uninstalls a specific module.

```bash
ncp module uninstall redis
```

---

### `ncp module status <name>`

Queries the runtime status of a module.

```bash
ncp module status nginx
```

---

### `ncp module upgrade <name>`

Upgrades a module to its latest version.

```bash
ncp module upgrade docker
```

---

## Provider Commands (Planned)

### `ncp provider list`

Lists all available providers.

```bash
ncp provider list
```

---

### `ncp provider use <name>`

Sets the active provider for operations.

```bash
ncp provider use google
ncp provider use icn
```

---

## Template Commands (Planned)

### `ncp template list`

Lists all available application templates.

```bash
ncp template list
```

---

### `ncp template apply <name>`

Applies a template to the current working directory.

```bash
ncp template apply react
ncp template apply laravel
```

---

## CLI Architecture

```
cli/
├── ncp                     — CLI entrypoint
└── commands/
    ├── help.sh             — help command
    ├── version.sh          — version command
    ├── doctor.sh           — doctor command
    ├── install.sh          — install command (planned)
    ├── module.sh           — module subcommand router (planned)
    ├── provider.sh         — provider subcommand router (planned)
    └── template.sh         — template subcommand router (planned)
```

---

## Exit Codes

All CLI commands follow the NCP standard exit code contract. See [exit-codes.md](./exit-codes.md) for the full reference.
