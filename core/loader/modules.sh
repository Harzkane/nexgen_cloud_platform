
#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

discover_modules() {

    find "$PROJECT_ROOT/modules" \
        -mindepth 2 \
        -maxdepth 2 \
        -type d \
        | sort

}