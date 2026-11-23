#!/usr/bin/env bash
# Route A (NVIDIA "Run your first agent"): OpenCode + hosted Nemotron 3.5 Lightning via OpenRouter, sandboxed.
# YOU run this in your own WSL terminal (OpenCode is an interactive TUI). Before running:
#   export OPENROUTER_API_KEY=sk-or-...      # free key from openrouter.ai; never paste it into chat or files
# Docs: https://docs.nvidia.com/openshell/latest/about/run-your-first-agent
set -euo pipefail
: "${OPENROUTER_API_KEY:?export OPENROUTER_API_KEY in this shell first}"

if ! openshell profile describe openrouter >/dev/null 2>&1; then
  openshell profile import --url https://raw.githubusercontent.com/NVIDIA/OpenShell/main/providers/openrouter.yaml
fi
openshell provider get openrouter >/dev/null 2>&1 || \
  openshell provider create --name openrouter --type openrouter --from-existing

cat <<'EOF'
Provider ready. The key now lives in the gateway; the sandbox only gets a placeholder.

Start the agent (interactive):
  openshell sandbox create --name my-agent --from ghcr.io/anomalyco/opencode:latest \
    --provider openrouter -- opencode -m openrouter/nvidia/nemotron-3.5-lightning:free

Inside OpenCode, ask it to fetch a web page (e.g. "fetch https://docs.nvidia.com/openshell/latest/ and summarise it").
In a second WSL terminal:
  openshell rule get my-agent --status pending          # wait ~10s for the denial analysis
  openshell rule approve my-agent --chunk-id <chunk-id>  # or:
  openshell rule reject  my-agent --chunk-id <chunk-id> --reason "Not needed for this task."
  openshell rule history my-agent > evidence/route-a-rule-history.txt
  openshell policy get my-agent --full > evidence/route-a-policy-full.txt
EOF
