#!/usr/bin/env bash

set -euo pipefail

read_metadata_value() {

    local file="$1"
    local key="$2"

    grep "^${key}:" "$file" | head -n1 | cut -d':' -f2- | xargs

}