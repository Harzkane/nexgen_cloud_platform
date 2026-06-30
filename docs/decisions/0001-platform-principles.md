# ADR 0001: Platform Engineering Principles

* **Status:** Approved
* **Author:** NexGen Tech Architecture Team
* **Date:** 2026-06-30

---

## Context & Problem Statement

As NCP grows from a set of deployment scripts into a modular infrastructure product, we need a shared set of architectural guidelines. Without explicit principles, the project risks becoming a collection of unmaintainable, monolithic, state-dependent shell scripts that break under different conditions.

## Decision Rules & Core Principles

We approve the following five core principles as the design guidelines for all NCP code:

### Principle 1: Everything is Modular
- Code must not live in bloated, monolithic scripts like `install_everything.sh`.
- Each infrastructure component must be built as a self-contained module in `modules/` (e.g. `modules/docker`, `modules/firewall`, `modules/nginx`).
- Modules should have a clean, standard layout.

### Principle 2: Everything is Idempotent
- Running any script or installer action 10 times consecutively must yield the same final state without breaking the server or introducing duplicate configurations.
- Scripts must explicitly detect whether an action is already completed before running command sequences (e.g., checking if Docker is already installed or a firewall port is already opened).

### Principle 3: Everything is Testable
- Every script and component module must support testable operations.
- Modules must provide the following standard hook interfaces where applicable:
  - `install()`: Setting up the module.
  - `verify()`: Running tests/verifications to confirm success.
  - `status()`: Querying runtime health.
  - `uninstall()`: Tear down and revert settings.

### Principle 4: Everything Produces Logs
- Silent failures are unacceptable.
- Commands must log structured execution data to log files located in standard directories (e.g., `logs/`).
- System tools must log debug-level output to trace problems.

### Principle 5: Every Action Returns a Result
- CLI commands and scripts must return clear, structured statuses (Success/Failure status, duration, version, stdout/stderr logs) rather than generic text prints.
- System outputs must indicate exactly what happened and why.

---

## Consequences

* **Pros:** Highly predictable server state, clean debug cycle, easy testing, modular expansion.
* **Cons:** Takes slightly longer to write code initially since checks for idempotency, logging, and error handling must be built into every step.
