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

NCP manages the lifecycle of the host server and its deployment environments across three primary layers:

### 1. The OS Layer (Installer Engine)
- Operating system updates and essentials.
- Firewall configurations (UFW) and intrusion prevention (Fail2Ban).
- User security (disabling password auth, root logins, enforcing SSH keys).

### 2. The Platform Layer (Module & Provider Engines)
- Docker & Docker Compose orchestrations.
- Reverse proxying, routing, and SSL (Nginx & Let's Encrypt).
- Standardized database clusters (PostgreSQL, MongoDB, MySQL, Redis).

### 3. The Application Layer (Template Engine)
- Creating standardized directory structures on the host (`/opt/nexgen`).
- Instantiating standard project templates (Node, React, Laravel, FastAPI, etc.).
- GitHub Actions CI/CD workflows for git-push deployments.
