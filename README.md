# NexGen Cloud Platform (NCP)

NexGen Cloud Platform (NCP) is an internal, standardized infrastructure platform designed to deploy, secure, configure, and monitor services across all NexGen environments (including **AfriX**, **AfriRail**, **KaliSukaar**, and client hostings). 

NCP transforms a fresh Ubuntu VM into a production-grade environment with zero manual steps, consistent configurations, and full observability.

---

## 📁 Repository Structure

This repository is organized as a modular infrastructure framework:

```
nexgen_cloud_platform/
├── README.md              # Project overview and roadmap
├── core/                  # Core orchestration engines
│   ├── installer/         # Host OS setup and VM provisioning engine
│   ├── module-engine/     # Module manager and lifecycle orchestrator
│   ├── provider-engine/   # Cloud provider driver/API abstraction
│   ├── template-engine/   # Project boilerplate/framework generator
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
├── modules/               # Platform modules (Docker Compose & Configurations)
│   ├── docker/            # Docker engine and daemon configs
│   ├── nginx/             # Reverse proxy and site configs
│   ├── postgres/          # PostgreSQL cluster config
│   ├── mongodb/           # MongoDB config
│   ├── mysql/             # MySQL/MariaDB config
│   ├── redis/             # Redis caching config
│   ├── ssl/               # Let's Encrypt and cert renewal configurations
│   ├── backup/            # Automatic backup and encryption scripts
│   ├── monitoring/        # Prometheus, Grafana, alerts config
│   ├── firewall/          # UFW and Fail2Ban security configs
│   └── github-actions/    # CI/CD workflows and deployment configurations
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

The development of NCP follows these structured phases:

1. **Phase 1 — Foundation:** Create a production-grade Ubuntu base (Automatic updates, swap space, SSH hardening, UFW firewall, Fail2Ban).
2. **Phase 2 — Container Platform:** Docker and Docker Compose environment configuration.
3. **Phase 3 — Networking:** Reverse proxying using Nginx, Let's Encrypt SSL auto-renewal, compression, and security headers.
4. **Phase 4 — Application Framework:** Setting up `/opt/nexgen/{apps,shared,logs,backups,scripts,docker,nginx}` filesystem layout.
5. **Phase 5 — CI/CD:** GitHub Actions runner integration and SSH deploy scripts with health checks.
6. **Phase 6 — Observability:** Server metrics monitoring, Docker container health, and SSL certificate expiration alerts.
7. **Phase 7 — Disaster Recovery:** Daily encrypted database backups and retention policies.
8. **Phase 8 — Internal CLI:** Develop the `nexgen` CLI to bootstrap, deploy, and monitor environments.
9. **Phase 9 — The "ICN Test":** Validation checklist to match physical/VPS server specs with our reference environments.
10. **Phase 10 — The Future:** Hosting platform layer capable of managing multi-tenant client deployments.
