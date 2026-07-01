# NCP Component Types Reference

> **Schema Version:** `ncp.io/v1`

---

## Overview

NCP components are the building blocks of the platform. Every component is described by a `manifest.yml` file and discovered dynamically by the Core Engine.

The `kind` field in every manifest declares the component type.

```yaml
kind: Module
```

---

## Supported Kinds

### Module

A **Module** is a self-contained, installable infrastructure unit.

Modules manage discrete system responsibilities such as installing Docker, configuring a firewall, or provisioning a database. They are located under `modules/`.

```yaml
kind: Module
```

**Examples:** `docker`, `nginx`, `postgres`, `redis`, `fail2ban`, `ssl`

---

### Provider

A **Provider** is a cloud infrastructure driver.

Providers manage VM provisioning, networking, and deployment targeting for a specific hosting platform. They are located under `providers/`.

```yaml
kind: Provider
```

**Examples:** `google`, `aws`, `azure`, `icn`, `hetzner`, `local`

---

### Template

A **Template** is a reusable application boilerplate.

Templates define a complete application stack including Docker Compose configuration, Nginx rules, environment variables, and CI/CD pipelines. They are located under `templates/`.

```yaml
kind: Template
```

**Examples:** `react`, `vue`, `node`, `laravel`, `django`, `fastapi`, `microservices`

---

### Runtime

A **Runtime** is a language execution environment module.

Runtimes install and configure programming language environments on the target server. They are located under `modules/runtime/`.

```yaml
kind: Runtime
```

**Examples:** `node`, `python`, `php`, `java`, `dotnet`

---

### Service

A **Service** is an internal NCP platform service.

Services extend the platform itself (e.g., the NCP API, dashboard, or internal orchestration workers). Reserved for future NCP platform capabilities.

```yaml
kind: Service
```

---

### Extension

An **Extension** adds optional, non-core capabilities to NCP.

Extensions are community or internal add-ons that expand NCP without modifying the Core Engine.

```yaml
kind: Extension
```

---

## Component Directory Mapping

| Kind | Directory |
|------|-----------|
| Module | `modules/<category>/<name>/` |
| Provider | `providers/<name>/` |
| Template | `templates/<name>/` |
| Runtime | `modules/runtime/<name>/` |
| Service | Reserved |
| Extension | Reserved |

---

## Component Status Values

Every component declares a maturity level using the `status` field:

| Value | Meaning |
|-------|---------|
| `stable` | Production-ready and fully tested |
| `beta` | Feature complete but may have minor issues |
| `experimental` | Under active development, breaking changes possible |
| `deprecated` | Scheduled for removal in a future version |
