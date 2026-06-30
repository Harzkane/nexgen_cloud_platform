# NCP Architecture Overview

The NexGen Cloud Platform (NCP) is built around a modular architecture composed of specialized engines. This design ensures clear separation of concerns, makes the codebase easy to maintain, and simplifies extensions.

---

## 🏛️ System Core Architecture

```
                       ┌─────────────────────────┐
                       │     NCP CLI Engine      │
                       └────────────┬────────────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         ▼                          ▼                          ▼
┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
│Installer Engine │        │  Module Loader  │        │Provider Engine  │
└─────────────────┘        └─────────────────┘        └─────────────────┘
         │                          │                          │
         ▼                          ▼                          ▼
┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
│Validator Engine │        │ Logging Engine  │        │Template Engine  │
└─────────────────┘        └─────────────────┘        └─────────────────┘
```

### 1. CLI Engine (`cli/`)
- Acts as the entrypoint for developers and administrators.
- Parses user input and delegates commands to the corresponding Core Engines.
- Provides user-friendly output and standard reporting formats.

### 2. Installer Engine (`core/installer/`)
- Responsible for configuring the bare OS, including base packages, users, security (SSH, UFW, Fail2Ban), and container runtime utilities (Docker).
- Prepares the server directory structures.

### 3. Module Loader & Engine (`core/loader/` & `core/module-engine/`)
- Parses module metadata (`metadata.yml`), resolves module dependencies, and dynamically executes standard hooks (`install()`, `verify()`, `status()`, `uninstall()`).

### 4. Provider Engine (`core/provider-engine/`)
- Abstracts API and provisioning actions for specific hosting environments (Google Cloud, ICN, AWS, Azure, Hetzner, Local).
- Standardizes host discovery and VM access.

### 5. Template Engine (`core/template-engine/`)
- Scaffolds standardized directory structures and templates for new application deployments (Node, React, Laravel, etc.) inside the system directory.

### 6. Validator Engine (`core/validator/`)
- Performs health verification, checks configs, validates SSL status, and runs check tests to confirm the server matches the target NCP baseline specification.

### 7. Logging Engine (`core/logger/`)
- Consolidated, structured logging utility to output execution status, failure reports, and runtime logs for all active modules.

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
