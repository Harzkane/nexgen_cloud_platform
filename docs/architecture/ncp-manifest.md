# NCP Manifest Specification

The NCP Manifest (`ncp.yml` or `ncp.yaml`) is the single source of truth for applications managed by the NexGen Cloud Platform. It specifies stack configurations, target environments, runtime requirements, databases, and dependencies.

Instead of manual server configuration, the NCP CLI reads this manifest and drives the Kernel engines to provision, configure, and monitor the target stack deterministically.

---

## 📄 Manifest Schema Structure

```yaml
apiVersion: ncp.io/v1
kind: Application

metadata:
  name: afrirail
  version: 1.0.0
  environment: production

provider:
  type: google             # google | icn | aws | azure | hetzner | local
  region: us-central1
  machineType: e2-micro

runtime:
  language: node           # node | python | php | java | dotnet
  version: 20-alpine

database:
  type: postgres           # postgres | mongodb | mysql | mariadb | redis
  version: 15-alpine
  persistence:
    size: 10Gi

frontend:
  framework: react         # react | vue | none
  proxyPath: /

modules:
  - nginx                  # reverse-proxy routing
  - ssl                    # Let's Encrypt certificate renewal
  - monitoring             # system/metrics/logs status tracking
  - backup                 # daily encrypted filesystem & database backups
```

---

## ⚙️ Section Details

### 1. Root Attributes
- `apiVersion`: The configuration schema version (currently `ncp.io/v1`).
- `kind`: The deployment resource type (typically `Application`).

### 2. `metadata`
- `name`: Unique name of the application stack.
- `version`: Version string of the application.
- `environment`: Deployment stage target (`production`, `staging`, `development`).

### 3. `provider`
- `type`: Target hosting provider matching drivers in `providers/`.
- `region`/`machineType`: Provider-specific provisioning specifications used by the Provider Engine.

### 4. `runtime`
- `language`: Target run language matching stack templates in `templates/`.
- `version`: Execution container image tag or environment version.

### 5. `database`
- `type`: Relational or NoSQL database service module.
- `version`: Target database version.
- `persistence`: Host volume storage parameters.

### 6. `modules`
- A list of optional pluggable infrastructure modules (from `modules/`) to be activated, validated, and run alongside the application.
