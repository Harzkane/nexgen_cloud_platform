
#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

discover_templates() {

    find "$PROJECT_ROOT/templates" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        | sort

}