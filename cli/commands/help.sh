#!/usr/bin/env bash

set -euo pipefail

cat <<EOF

NexGen Cloud Platform (NCP)

Usage:

    ncp <command> [arguments]

Commands

    doctor        Inspect the current system
    plan          Build and show execution plan for components
    install       Install specified components (use --dry-run to only plan)
    status        Check the execution status of a component
    verify        Verify a component's setup/health
    configure     Configure a component
    list          List all discovered NCP modules and installation status
    info          Show detailed metadata for a component
    operations    Show operations and execution log history
    version       Show NCP version
    help          Show this help message

EOF