# NCP Manifest Schema

> **Schema Version:** `ncp.io/v1`

---

## Overview

Every component in the NexGen Cloud Platform (NCP) is described by a **Manifest**.

The Manifest is the contract between the NCP Core Engine and every component in the platform.

The Core Engine never hardcodes knowledge about Docker, PostgreSQL, Google Cloud, ICN, or any other technology.

Instead, it discovers components by reading their `manifest.yml` files.

This architecture allows NCP to remain modular, extensible, and provider-agnostic.

---

# Manifest Location

Every component must contain a `manifest.yml` file in its root directory.

Example:

```text
modules/system/docker/
│
├── manifest.yml
├── install.sh
├── verify.sh
├── status.sh
├── configure.sh
├── upgrade.sh
└── uninstall.sh
```

---

# Required Fields

The following fields are mandatory for every manifest.

| Field | Description |
|--------|-------------|
| apiVersion | Manifest schema version |
| kind | Component type |
| id | Unique immutable component identifier |
| displayName | Human-readable component name |
| version | Component version |
| status | Lifecycle status |
| category | Component category |
| description | Component description |
| installOrder | Installation order |

---

# Optional Fields

The following sections are optional depending on the component.

- maintainer
- license
- dependencies
- compatibility
- lifecycle
- capabilities
- tags

---

# Supported Component Kinds

NCP currently defines the following component types.

| Kind | Description |
|--------|-------------|
| Module | Installable platform module |
| Provider | Infrastructure provider |
| Template | Application template |
| Runtime | Language runtime |
| Service | Internal platform service |
| Extension | Optional platform extension |

Additional kinds may be introduced in future schema versions.

---

# Component Identity

Every component has a permanent identity.

```yaml
id: docker

displayName: Docker Engine
```

## id

The immutable internal identifier.

This value must never change after release.

The Core Engine uses this value internally.

## displayName

Human-readable name displayed in the CLI, logs, dashboards, and documentation.

Unlike the `id`, the `displayName` may change over time.

---

# Component Status

Each component declares its maturity.

Supported values:

```yaml
status: stable
```

```yaml
status: beta
```

```yaml
status: experimental
```

```yaml
status: deprecated
```

The Engine may warn users when installing unstable or deprecated components.

---

# Installation Order

Components may depend on one another.

The installation order determines execution sequence.

Example:

```yaml
installOrder: 20
```

Lower numbers execute first.

---

# Dependencies

Components may declare required dependencies.

Example:

```yaml
dependencies:

  - id: git
    version: ">=2.0"
```

Future versions of NCP will automatically resolve dependency graphs before installation.

---

# Compatibility

Components declare supported operating systems.

Example:

```yaml
compatibility:

  ubuntu:
    - "22.04"
    - "24.04"

  debian:
    - "12"
```

Future versions may also support:

- Rocky Linux
- AlmaLinux
- Fedora
- CentOS Stream
- macOS
- Windows

---

# Lifecycle

Lifecycle describes executable actions supported by a component.

Example:

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

The Engine executes lifecycle actions instead of calling scripts directly.

---

# Capabilities

Capabilities describe what a component is capable of performing.

Example:

```yaml
capabilities:
  - install
  - verify
  - configure
  - upgrade
  - uninstall
```

The Engine uses capabilities to determine available operations without hardcoded logic.

---

# Tags

Tags improve searching, filtering, and documentation.

Example:

```yaml
tags:
  - docker
  - containers
  - runtime
```

---

# Manifest Validation

Every manifest must pass schema validation before it can be loaded by the Core Engine.

Validation includes:

- Required fields
- Supported schema version
- Valid component kind
- Valid lifecycle definitions
- Dependency syntax
- Compatibility syntax

Invalid manifests are rejected during discovery.

---

# Versioning

The manifest schema follows semantic versioning.

Current version:

```text
ncp.io/v1
```

Future versions may introduce:

```text
ncp.io/v2
```

Older manifests should continue to function whenever possible.

---

# Design Principles

The NCP Manifest is designed around the following principles:

- Declarative over imperative
- Convention over configuration
- Extensible by design
- Provider agnostic
- Cloud native
- Human-readable
- Machine-parseable
- Backward compatible whenever practical

---

# Example Manifest

```yaml
apiVersion: ncp.io/v1

kind: Module

id: docker

displayName: Docker Engine

version: 1.0.0

status: stable

category: system

description: Install and manage Docker Engine.

maintainer: NexGen Tech

license: MIT

installOrder: 20

dependencies:
  - id: git
    version: ">=2.0"

compatibility:
  ubuntu:
    - "22.04"
    - "24.04"

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

capabilities:
  - install
  - verify
  - configure
  - upgrade
  - uninstall

tags:
  - docker
  - containers
  - runtime
```