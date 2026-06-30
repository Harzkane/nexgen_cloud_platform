# ADR 0002: Unified Module Standard & Lifecycle Contract

* **Status:** Approved
* **Author:** NexGen Tech Architecture Team
* **Date:** 2026-07-01

---

## Context & Problem Statement

To prevent the core engine from containing hardcoded execution logic, we need to treat modules, templates, and cloud providers as pluggable extensions. Every component needs a standardized layout and an explicit lifecycle contract so that the core kernel engine can discover, validate, sort, execute, and verify them dynamically.

---

## Decision Rules & Specification

We approve the following unified layout structure and 8-stage lifecycle contract for all pluggable plugins (Modules, Providers, and Templates).

### 1. File Layouts

#### A. Modules (`modules/<category>/<module-name>/`)
Every module must be self-contained and implement the following structure:
```text
modules/databases/postgres/
├── metadata.yml      # Module attributes, dependencies, priority
├── install.sh        # Installation runner script
├── verify.sh         # Sanity check script
├── status.sh         # Runtime status check script
├── configure.sh      # Configuration runner script
├── upgrade.sh        # Version patch/upgrade script
├── uninstall.sh      # Reversion/cleanup script
└── README.md         # Documentation
```

#### B. Providers (`providers/<provider-name>/`)
Providers manage target platform VM deployment and orchestration:
```text
providers/google/
├── metadata.yml      # Provider specifications
├── deploy.sh         # Provisions server VM
├── destroy.sh        # Teardown provisioning
├── status.sh         # Cloud status checker
├── verify.sh         # Connection validator
└── README.md         # Documentation
```

#### C. Templates (`templates/<template-name>/`)
Templates define pre-configured application boilerplates:
```text
templates/react/
├── metadata.yml          # Stack requirements
├── docker-compose.yml    # Service runtime composition
├── nginx.conf            # Proxy rules
├── .env.example          # Template environment configurations
├── github-actions.yml    # CI/CD deployment pipelines
└── README.md             # Documentation
```

---

### 2. Standard `metadata.yml` Schema
The `metadata.yml` file is the source of truth for the Core Engine's loader:
```yaml
name: docker
version: 1.0.0
description: "Install and configure Docker container runtime"
type: module           # module | provider | template
priority: 20           # Low is executed first (e.g., git=10, docker=20)
requires:              # Dependency requirements list
  - git
supported_os:
  - ubuntu-22.04
  - ubuntu-24.04
```

---

### 3. The 8-Stage Module Lifecycle
When NCP runs system operations, it coordinates modules across 8 standard phases:

1. **Discover:** The Loader engine scans directories, parses `metadata.yml` files, and builds a directed acyclic graph (DAG) of priorities/dependencies.
2. **Validate:** The Validator checks that the OS is supported, user has sudo privileges, internet is active, and dependencies are met before making changes.
3. **Install:** Executes package installations and system binaries setup (`install.sh`).
4. **Verify:** Runs automated testing (`verify.sh`) to confirm packages respond correctly.
5. **Configure:** Mounts directories, sets configuration files, writes credentials/environment variables (`configure.sh`).
6. **Status:** Returns active running status, process logs, and health flags (`status.sh`).
7. **Upgrade:** Patches or upgrades configuration files and versions safely (`upgrade.sh`).
8. **Uninstall:** Completely removes module files, purges packages, and restores OS parameters (`uninstall.sh`).

---

## Consequences

* **Pros:** Clean separation of concerns. Developers can write new modules or templates without modifying any CLI or kernel orchestration code.
* **Cons:** Every script needs to support standard exit codes (`0` for success, non-zero for failures) so the core engine can log outcomes properly.
