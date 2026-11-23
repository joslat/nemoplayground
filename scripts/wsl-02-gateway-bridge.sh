#!/usr/bin/env bash
# Installs openshell/gateway.toml (Docker driver in bridge mode) and restarts the gateway.
# Required on Windows + WSL 2 + Docker Desktop; see the comments in openshell/gateway.toml.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ~/.config/openshell
install -m 600 openshell/gateway.toml ~/.config/openshell/gateway.toml
echo '$ openshell-gateway config preflight'
openshell-gateway config preflight
systemctl --user restart openshell-gateway
for i in $(seq 1 30); do openshell status >/dev/null 2>&1 && break; sleep 1; done
openshell status
