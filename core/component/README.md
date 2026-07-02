# NCP Component Package

This package manages the high-level in-memory representations of NCP components (Modules, Providers, and Templates).

## Structure

- **`loader.sh`**: Translates a physical component folder containing a `manifest.yml` into structured, memory-resident Component shell variables.
- **`registry.sh`**: Keeps track of all loaded components and exposes lookup and query operations.
- **`resolver.sh`**: Performs topological sort and dependency resolution to ensure components are installed/configured in the correct order.

## Component Object Representation

Due to Bash 3.2 compatibility constraints, components are represented using dynamic variables of the format:

```bash
NCP_COMP_<ID>_<PROPERTY>
```

For example:
- `NCP_COMP_docker_displayName="Docker Engine"`
- `NCP_COMP_docker_version="1.0.0"`
- `NCP_COMP_docker_dependencies_count=1`
- `NCP_COMP_docker_dependencies_0_id="git"`
