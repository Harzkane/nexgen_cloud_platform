# NexGen Cloud Platform (NCP)

NexGen Cloud Platform (NCP) is an internal, standardized infrastructure platform designed to deploy, secure, configure, and monitor services across all NexGen environments (including **AfriX**, **AfriRail**, **KaliSukaar**, and client hostings). 

NCP transforms a fresh Ubuntu VM into a production-grade environment with zero manual steps, consistent configurations, and full observability.

---

## 📁 Repository Structure

This repository is organized as a modular infrastructure framework:

```
nexgen_cloud_platform/
├── README.md              # Project overview and roadmap
├── core/                  # Core orchestration engines (NCP Kernel)
│   ├── engine/            # Central orchestration engine and lifecycle controller
│   ├── installer/         # Host OS setup and VM provisioning engine
│   ├── loader/            # Module loader and dependency resolver
│   ├── logger/            # Platform logging and report generation
│   ├── provider-engine/   # Cloud provider driver/API abstraction
│   ├── utils/             # Core utility helpers and CLI extensions
│   └── validator/         # Sanity validation and verification engine
├── cli/                   # Internal command-line interface (e.g., `nexgen` CLI)
├── docs/                  # Architecture, guides, and ADRs
│   ├── architecture/      # High-level architecture details
│   ├── diagrams/          # System design diagrams
│   ├── guides/            # Server administration and runbook guides
│   ├── roadmap/           # Long-term platform roadmap
│   └── decisions/         # Architectural Decision Records (ADRs)
├── templates/             # Application framework templates
│   ├── node/              # Node.js backend boilerplate
│   ├── react/             # React SPA setup
│   ├── vue/               # Vue SPA setup
│   ├── laravel/           # Laravel setup
│   ├── django/            # Django setup
│   ├── fastapi/           # FastAPI setup
│   └── microservices/     # Multi-container microservice skeleton
├── modules/               # Reusable modules (idempotent setup & lifecycle)
│   ├── system/            # System tools (git, curl, build-tools, docker, nginx)
│   ├── databases/         # Database services (postgres, mongodb, mysql, mariadb, redis)
│   ├── security/          # Security setups (firewall, fail2ban, ssl, ssh)
│   ├── monitoring/        # Health and status tracking (uptime, metrics, logs, alerts)
│   ├── backup/            # Data backup tasks (filesystem, postgres, mongodb, s3)
│   ├── ci/                # CI/CD runners (github-actions, gitlab, webhook)
│   ├── networking/        # Routing structures (dns, reverse-proxy, load-balancer)
│   └── runtime/           # Language runs (node, python, php, java, dotnet)
├── providers/             # Infrastructure provider integrations
│   ├── google/            # Google Cloud Platform configuration
│   ├── icn/               # ICN cloud provider configuration
│   ├── aws/               # Amazon Web Services configuration
│   ├── azure/             # Microsoft Azure configuration
│   ├── hetzner/           # Hetzner Cloud configuration
│   └── local/             # Local development / bare-metal environment
├── scripts/               # Helper and utility scripts
├── examples/              # Reference implementation examples
├── tests/                 # Infrastructure and sanity verification checks
└── assets/                # Logos, images, and static resources
```

---

## 🚀 The Vision

Our goal is to treat infrastructure as code (IaC) to enforce a single, secure, and production-ready standard for every single VM we spin up:
- **Zero Manual Steps:** A single command initializes, secures, and configures the environment.
- **Predictable Abstractions:** All apps run inside containerized stacks under `/opt/nexgen`.
- **Automated CI/CD:** Pushing code to GitHub automatically builds, checks health, and deploys.
- **Robust Disaster Recovery:** Daily backups are compressed, encrypted, and uploaded to off-site storage.

---

## 🗺️ Implementation Roadmap

The development of NCP is structured around the following release milestones:

- **v0.1-alpha (Module Discovery):** Module Discovery Engine + Metadata Parser + `ncp doctor` (zero-touch validation).
- **v0.1-beta (Installer Engine):** Engine Orchestrator + Logging Engine + Validator.
- **v0.1.0 (Foundation Core):** Hardened Ubuntu OS base configuration (Git, Curl, Docker, Firewall, Fail2Ban, SSH).
- **v0.2.0 (Databases & Runtimes):** Configuration modules for runtimes (Node, Python) and databases (Postgres, Mongo, Redis).
- **v0.3.0 (Templates):** Application templates deployment (React, Vue, Laravel, FastAPI).
- **v0.4.0 (Providers):** Target provider drivers (GCP first, then ICN, AWS, Local).
