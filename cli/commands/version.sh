#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

VERSION="$(cat "$PROJECT_ROOT/VERSION")"

echo "NexGen Cloud Platform"
echo "Version: $VERSION"