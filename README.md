# NexGen Cloud Platform (NCP)

> Build once. Deploy anywhere. Manage everything.

NexGen Cloud Platform (NCP) is a provider-agnostic infrastructure platform developed by NexGen Tech to provision, configure, secure, deploy, and manage production servers consistently across multiple cloud providers.

Rather than being a collection of installation scripts, NCP is a modular platform driven by manifests, lifecycle hooks, and reusable infrastructure components.

Its mission is simple:

> Transform any supported Ubuntu server into a production-ready environment with a single command.

---

# Why NCP?

Modern deployments often become tightly coupled to a specific cloud provider or hosting platform.

NCP removes that dependency.

Whether the server lives on:

- Google Cloud
- ICN Cloud
- AWS
- Azure
- Hetzner
- DigitalOcean
- Local VM
- Bare Metal

the deployment workflow remains identical.

---

# Core Philosophy

NCP is built around a few core principles.

- Infrastructure as Code
- Provider Agnostic
- Manifest Driven
- Modular
- Declarative
- Idempotent
- Secure by Default
- Observable
- Testable
- Extensible

---

# Repository Structure

```text
nexgen_cloud_platform/

├── README.md
├── VERSION
├── CHANGELOG.md
├── LICENSE

├── cli/
│   ├── ncp
│   ├── commands/
│   └── completion/

├── core/
│   ├── discovery/
│   ├── engine/
│   ├── installer/
│   ├── logger/
│   ├── utils/
│   └── validator/

├── manifest/
│   ├── loader.sh
│   ├── parser.sh
│   └── validator.sh

├── modules/
├── providers/
├── templates/

├── docs/
├── tests/
├── examples/
├── scripts/
├── assets/
└── workspace/
```

---

# NCP Kernel

The platform is composed of several independent engines.

```text
                NCP Kernel

              CLI (ncp)

                    │

                    ▼

         Discovery Engine

                    │

                    ▼

          Manifest Engine

                    │

                    ▼

        Validation Engine

                    │

                    ▼

      Dependency Resolver

                    │

                    ▼

        Lifecycle Engine

                    │

                    ▼

          Installer Engine

                    │

                    ▼

          Logging Engine
```

Each engine has one responsibility.

This keeps the platform modular and easy to extend.

---

# Platform Architecture

NCP does not hardcode infrastructure logic.

Instead, every component describes itself through a manifest.

```text
Module

↓

manifest.yml

↓

Discovery Engine

↓

Manifest Parser

↓

Manifest Validator

↓

Dependency Resolver

↓

Lifecycle Executor

↓

Installation
```

Adding a new module does not require modifying the Core Engine.

Simply place a new module inside `modules/` with a valid `manifest.yml`.

NCP automatically discovers it.

---

# Component Types

NCP currently supports three component types.

## Modules

Reusable infrastructure components.

Examples:

- Docker
- Git
- Nginx
- PostgreSQL
- Redis
- Firewall

---

## Providers

Infrastructure drivers.

Examples:

- Google Cloud
- ICN
- AWS
- Azure
- Hetzner
- Local

---

## Templates

Application deployment templates.

Examples:

- Node.js
- React
- Vue
- Laravel
- Django
- FastAPI
- Microservices

---

# Module Lifecycle

Every module follows the exact same lifecycle.

```text
manifest.yml

↓

discover

↓

validate

↓

dependency resolution

↓

install

↓

verify

↓

configure

↓

status

↓

upgrade

↓

uninstall
```

This standardized lifecycle guarantees predictable deployments across every module.

---

# Manifest Driven Architecture

Every component inside NCP contains a `manifest.yml`.

Example:

```yaml
apiVersion: ncp.io/v1

kind: Module

name: docker

displayName: Docker Engine

version: 1.0.0
```

The manifest describes:

- metadata
- dependencies
- lifecycle hooks
- supported operating systems
- capabilities
- execution priority

The Core Engine never contains Docker-specific logic.

Instead, it reads the manifest and executes the lifecycle dynamically.

---

# Current Repository Layout

The platform currently contains:

## CLI

- doctor
- version
- help

---

## Core

- Discovery Engine
- Validation Engine
- Installer
- Logger
- Utilities
- Engine

---

## Manifest Engine

- Parser
- Validator
- Loader

---

## Modules

- System
- Databases
- Security
- Monitoring
- Backup
- Networking
- Runtime
- CI

---

## Providers

- Google Cloud
- ICN
- AWS
- Azure
- Hetzner
- Local

---

## Templates

- Node
- React
- Vue
- Laravel
- Django
- FastAPI
- Microservices

---

# Development Workflow

NCP is developed using a real production workflow.

```text
Mac Development Machine

↓

GitHub

↓

Google Cloud Ubuntu VM

↓

NCP Validation

↓

Production Ready
```

Every feature is tested on an actual Ubuntu server before it is merged.

---

# Roadmap

## v0.1-alpha

✅ CLI

✅ Discovery Engine

✅ Manifest Parser

✅ Manifest Validator

✅ Doctor Command

---

## v0.1-beta

- Installer Engine
- Dependency Resolver
- Lifecycle Engine
- Module Executor

---

## v0.2

Production system modules

- Git
- Curl
- Build Tools
- Docker
- Nginx
- Firewall
- SSH
- Fail2Ban

---

## v0.3

Databases

- PostgreSQL
- MongoDB
- MariaDB
- MySQL
- Redis

Runtime environments

- Node.js
- Python
- PHP
- Java
- .NET

---

## v0.4

Application Templates

- React
- Vue
- Laravel
- Django
- FastAPI
- Microservices

---

## v0.5

Cloud Providers

- Google Cloud
- ICN
- AWS
- Azure
- Hetzner
- Local

---

## v1.0

Production Release

Features include:

- Multi-provider deployments
- Automated provisioning
- Infrastructure validation
- Application templates
- Deployment orchestration
- Monitoring
- Backup
- Security hardening

---

# Current Status

Version

```
v0.1-alpha
```

Implemented

- ✅ CLI
- ✅ Module Discovery
- ✅ Provider Discovery
- ✅ Template Discovery
- ✅ Manifest Parser
- ✅ Manifest Validator
- ✅ Doctor Command

In Progress

- ⏳ Dependency Resolver
- ⏳ Lifecycle Engine
- ⏳ Installer Engine

Planned

- Module Installation
- Provider Drivers
- Template Deployment

---

# Long-Term Vision

NexGen Cloud Platform is the internal infrastructure foundation for every NexGen product.

Including:

- AfriX
- AfriRail
- KaliSukaar
- NexGen Internal Services
- Client Infrastructure

The goal is to make infrastructure deployment predictable, portable, secure, and fully reproducible regardless of the underlying cloud provider.

---

# License

This project is licensed under the MIT License.