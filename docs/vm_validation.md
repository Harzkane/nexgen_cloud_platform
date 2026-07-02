# NCP Google Cloud VM Validation Guide

This document outlines the step-by-step validation process for running the **NexGen Cloud Platform (NCP)** on the Google Cloud VM target instance. 

---

## 🖥️ Target Environment Specifications
* **OS**: Ubuntu 24.04.4 LTS (Noble Numbat)
* **Kernel**: Linux 6.17.0-1020-gcp x86_64
* **Init System**: systemd 255
* **Package Manager**: apt 2.8.3
* **User**: `codewithharz`

---

## 🛠️ Step 1: VM Preparation & Setup

Before running NCP, spend 5 minutes preparing the VM environment:

### 1. Update and Upgrade Packages
```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Required Core Utilities
Ensure git and curl are present on the target OS:
```bash
sudo apt install -y git curl
```

### 3. Clone and Enter the NCP Repository
```bash
git clone https://github.com/Harzkane/nexgen_cloud_platform.git
cd nexgen_cloud_platform
```

### 4. Make the CLI Entrypoint Executable
```bash
chmod +x cli/ncp
```

---

## 🔍 Step 2: Stage-by-Stage Verification

Validate the engine progressively to ensure everything functions correctly before executing complex module deployments.

### Stage 1 — Discovery & System Self-Check
Run the full environment check to verify permissions, Bash configurations, and directory writability:
```bash
./cli/ncp doctor --full
```
**Expected Outcome:**
Every test prints a green checkmark (`✓`) with `Environment Ready` at the end.

---

### Stage 2 — Registry & Modules Listing
Verify that the registry successfully parses and lists all discovered modules:
```bash
./cli/ncp list
```
**Expected Outcome:**
Lists all 33 registered components along with their version mappings.

---

### Stage 3 — Resource Action Planning
Test the declarative resource planner against the `git` system module:
```bash
./cli/ncp plan git
```
**Expected Outcome:**
Renders the resource plan showing:
```text
  Component: git
  Resources:
    CREATE package:git [id: git-package] (present)
```

---

### Stage 4 — Installation Execution
Run the installer to apply the declarative resource:
```bash
./cli/ncp install git
```
**Expected Outcome:**
- Executes the package installation using `apt-get`.
- Emits namespaced install events.
- Writes state configuration to `workspace/state/git.state` (including `desired_hash` fingerprint).
- Succeeds with `Git installed successfully.`

---

### Stage 5 — Drift Detection & Re-convergence
We will simulate a configuration drift to verify the Reconciler:

1. **Verify Healthy Status:**
   ```bash
   ./cli/ncp status git
   ```
   *Expected:* Component is marked `INSTALLED` and healthy.

2. **Simulate Configuration Drift:**
   Manually uninstall git from the operating system:
   ```bash
   sudo apt remove -y git
   ```

3. **Check for Drift:**
   ```bash
   ./cli/ncp status git --check-drift
   ```
   *Expected:* Output prints a warning that the resource has drifted, state transitions to `DRIFTED`, and the command exits with code **2**.

4. **Re-converge the State:**
   Re-run the installer to automatically fix the drifted state:
   ```bash
   ./cli/ncp install git
   ```
   *Expected:* Re-installs git and updates status back to `INSTALLED`.

---

## ⚠️ Things to Avoid Initially
As recommended by the reviewer, do **not** initially test:
* Rollback by intentionally breaking Docker.
* Service deletion.
* User creation.
* Uninstall logic.

Focus first on establishing the basic install, drift-check, and reconciliation flow.
