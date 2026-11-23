#!/usr/bin/env bash
# Installs the OpenShell CLI + local gateway inside WSL 2 Ubuntu (Docker Desktop backend).
# Run as the default (non-root) WSL user:  wsl -d Ubuntu-24.04 -- bash scripts/wsl-install-openshell.sh
set -euo pipefail
echo "--- whoami: $(whoami)"
echo "--- docker"
docker version --format 'client {{.Client.Version}} / server {{.Server.Version}} ({{.Server.Os}})'
echo "--- systemd"
systemctl is-system-running || true
systemctl --user is-system-running || true
echo "--- kernel / landlock"
uname -r
grep -o landlock /sys/kernel/security/lsm 2>/dev/null || echo "lsm file not readable (check config: CONFIG_LSM contains landlock)"

# Documented installer (https://docs.nvidia.com/openshell/latest/about/installation).
curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh

echo "--- verify"
command -v openshell
openshell --version || true
openshell status
