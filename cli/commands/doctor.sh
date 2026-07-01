#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "$PROJECT_ROOT/core/utils/output.sh"
source "$PROJECT_ROOT/core/loader/modules.sh"
source "$PROJECT_ROOT/core/loader/providers.sh"
source "$PROJECT_ROOT/core/loader/templates.sh"
source "$PROJECT_ROOT/core/loader/metadata.sh"
source "$PROJECT_ROOT/core/validator/environment.sh"

echo
echo "==========================================="
echo " NexGen Cloud Platform"
echo " Version: $(cat "$PROJECT_ROOT/VERSION")"
echo "==========================================="
echo

info "Environment"

echo "OS           : $(get_os_name)"
echo "Kernel       : $(get_kernel)"
echo "Architecture : $(get_architecture)"

echo

MODULE_COUNT=$(discover_modules | wc -l)
PROVIDER_COUNT=$(discover_providers | wc -l)
TEMPLATE_COUNT=$(discover_templates | wc -l)

info "Discovery"

# echo "Modules      : $MODULE_COUNT"
echo
info "Installed Module Definitions"

while IFS= read -r module; do

    metadata="$module/metadata.yml"

    if [ -f "$metadata" ]; then

        name=$(read_metadata_value "$metadata" "displayName")

        version=$(read_metadata_value "$metadata" "version")

        printf "  ✔ %-25s %s\n" "$name" "$version"

    fi

done < <(discover_modules)

echo "Providers    : $PROVIDER_COUNT"

echo "Templates    : $TEMPLATE_COUNT"

echo

success "NCP Discovery completed successfully."