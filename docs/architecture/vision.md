# NCP Vision & Mission

## 🌟 The Core Vision

NexGen Cloud Platform (NCP) is the unified infrastructure foundation for all NexGen Tech systems. It standardizes the deployment, security, and orchestration of application stacks across any target hosting provider.

Rather than treating servers as hand-crafted pets, NCP treats servers as cattle—provisioned, configured, and managed entirely through automated, reproducible code. 

```
┌─────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│ Fresh Ubuntu VM │ ───> │     Run NCP CLI/Core    │ ───> │ Production Ready Server │
└─────────────────┘      └─────────────────────────┘      └─────────────────────────┘
```

---

## 🎯 Strategic Goals

1. **Standardization:** Every server deployed for AfriX, AfriRail, KaliSukaar, or client projects must look exactly the same at the OS and container platform layer.
2. **Developer Autonomy:** Developers should be able to deploy their stack using standard templates without needing to manually SSH and configure firewalls, reverse proxies, or databases.
3. **Provider Agility:** Decouple applications from specific cloud providers. Whether hosting on Google Cloud, AWS, Hetzner, ICN, or a local machine, the application deployment interface remains identical.
4. **Reliability & Security:** Implement high security standards (UFW, Fail2Ban, SSH hardening) and system validation automatically.
5. **Observability:** Integrate central monitoring and status logging from day one.

---

## ⚙️ The Scope

NCP is structured as a five-layer platform engineering system where components remain independent and communicate strictly through the central Core Engine (Kernel):

```
                   ┌─────────────────────────┐
                   │       1. NCP CLI        │
                   └────────────┬────────────┘
                                │
                   ┌────────────▼────────────┐
                   │  2. Core Engine/Kernel  │
                   └────────────┬────────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   3. Modules    │    │  4. Templates   │    │  5. Providers   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
                   ┌────────────▼────────────┐
                   │ 6. Target Ubuntu Server │
                   └─────────────────────────┘
```

### 1. CLI Layer (`cli/`)
- Entrypoint command interface (`ncp`) parsing inputs, initiating checks, and executing user commands.

### 2. Core Engine / Kernel Layer (`core/`)
- The central brain consisting of the Installer, Loader, Validator, Logger, Engine, and Utilities. It manages module lifecycles and reads project configurations.

### 3. Modules Layer (`modules/`)
- Idempotent pluggable blocks (e.g. Docker, Nginx, PostgreSQL, Firewall rules) that execute configurations on the target server. Modules never talk directly to providers or templates.

### 4. Templates Layer (`templates/`)
- Reusable, framework-agnostic blueprints (e.g., React, Vue, Laravel, Django) defining site structures, container configurations, and proxy rules.

### 5. Providers Layer (`providers/`)
- Target hosting platform drivers (e.g., Google Cloud, ICN, AWS, Hetzner, Local) configuring the VMs and hardware targets.

