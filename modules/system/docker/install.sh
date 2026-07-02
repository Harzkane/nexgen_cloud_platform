#!/usr/bin/env bash
# NexGen Cloud Platform (NCP)
# Module: docker — Install Hook
# ============================================================

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/core/platform/packages.sh"
source "$PROJECT_ROOT/core/state/state.sh"
source "$PROJECT_ROOT/core/platform/os.sh"

os=$(get_os_name)

if [ "$os" = "Darwin" ]; then
    log_info "Installing Docker CLI on macOS via brew..."
    if brew install docker; then
        mark_installed "docker" "1.0.0"
        exit 0
    fi
elif [ "$os" = "Linux" ] && [ -f /etc/os-release ]; then
    log_info "Installing Docker Engine on Linux..."
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    if sudo apt-get install -y docker-ce docker-ce-cli containerd.io; then
        sudo systemctl enable docker || true
        sudo systemctl start docker || true
        mark_installed "docker" "1.0.0"
        exit 0
    fi
fi

mark_failed "docker" "Failed to install Docker"
exit 1
