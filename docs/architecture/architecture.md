# NCP Architecture Overview

The NexGen Cloud Platform (NCP) is built around a modular architecture composed of specialized engines. This design ensures clear separation of concerns, makes the codebase easy to maintain, and simplifies extensions.

---

## 🏛️ System Core Architecture

```
                       ┌─────────────────────────┐
                       │     NCP CLI Engine      │
                       └────────────┬────────────┘
                                    │
                                    ▼
                       ┌─────────────────────────┐
                       │   Core Engine Kernel    │
                       │     (core/engine/)      │
                       └────────────┬────────────┘
                                    │
         ┌──────────────┬───────────┼───────────┬──────────────┐
         ▼              ▼           ▼           ▼              ▼
┌──────────────┐ ┌──────────┐ ┌───────────┐ ┌───────────┐ ┌──────────┐
│  Installer   │ │  Loader  │ │ Validator │ │  Logger   │ │  Utils   │
│(installer/)  │ │(loader/) │ │(validator)│ │ (logger/) │ │ (utils/) │
└──────────────┘ └──────────┘ └───────────┘ └───────────┘ └──────────┘
```

### NCP Kernel Components

1. **CLI Engine (`cli/`):** The administrative command-line interface entrypoint.
2. **Core Orchestration Engine (`core/engine/`):** The orchestrator orchestrating all platform operations. It coordinates discovery, validation, provisioning, and logging.
3. **Installer Engine (`core/installer/`):** Orchestrates the baseline system installation workflows (packages, OS configuration, security hardening).
4. **Module Loader (`core/loader/`):** Dynamically scans, discovers, parses plugin configurations (`metadata.yml`), and builds module dependency graphs.
5. **Validator Engine (`core/validator/`):** Conducts pre-flight environment validations (OS type, active internet connection, admin privileges, existing packages, dependency satisfaction).
6. **Logging Engine (`core/logger/`):** Outputs structured execution status, logs, and installation reports.
7. **Utilities Engine (`core/utils/`):** Shared internal helper scripts and CLI extensions.

---

## 📁 System Directory Standard

Everything managed by NCP on the target host VM resides in `/opt/nexgen/`. Standard users and applications are kept out of `/home` to ensure environment predictability.

```
/opt/nexgen/
├── apps/               # Containerized applications (e.g., afrix, afrirail)
├── shared/             # Shared resources, persistent volume mounts
├── logs/               # Consolidated log files of all running modules
├── backups/            # Local, encrypted backup storage
├── scripts/            # Local administrative shell scripts
├── docker/             # Platform level Docker configurations
└── nginx/              # Reverse proxy rules, SSL certificates, site configs
```
