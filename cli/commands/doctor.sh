#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "$PROJECT_ROOT/core/utils/output.sh"
source "$PROJECT_ROOT/core/loader/modules.sh"
source "$PROJECT_ROOT/core/loader/providers.sh"
source "$PROJECT_ROOT/core/loader/templates.sh"
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

echo "Modules      : $MODULE_COUNT"

echo "Providers    : $PROVIDER_COUNT"

echo "Templates    : $TEMPLATE_COUNT"

echo

success "NCP Discovery completed successfully."