#!/usr/bin/env bash
# Route D, hosted variant: the same MafDemo image, calling hosted Nemotron on build.nvidia.com.
# Shows the credential story: the sandbox env holds only a placeholder, the gateway's proxy injects the
# real key for integrate.api.nvidia.com and only for /usr/share/dotnet/dotnet (see nvidia-dotnet.yaml).
# YOU run this in your own WSL terminal. Before running:
#   export NVIDIA_API_KEY=nvapi-...      # from build.nvidia.com; never paste it into chat or files
set -euo pipefail
cd "$(dirname "$0")/.."
: "${NVIDIA_API_KEY:?export NVIDIA_API_KEY in this shell first}"
MODEL="${MODEL:-nvidia/nemotron-3-nano-30b-a3b}"

if ! openshell profile describe nvidia-dotnet >/dev/null 2>&1; then
  openshell profile lint -f openshell/profiles/nvidia-dotnet.yaml
  openshell profile import -f openshell/profiles/nvidia-dotnet.yaml
fi
openshell provider get nvidia-dotnet >/dev/null 2>&1 || \
  openshell provider create --name nvidia-dotnet --type nvidia-dotnet --from-existing
unset NVIDIA_API_KEY   # the gateway has it now; nothing below needs it

openshell sandbox delete maf-hosted >/dev/null 2>&1 || true
openshell sandbox create --name maf-hosted --from maf-demo:1.0 --provider nvidia-dotnet --no-tty \
  --env OPENAI_BASE_URL=https://integrate.api.nvidia.com/v1 --env MODEL="$MODEL" \
  -- dotnet /usr/local/lib/mafdemo/MafDemo.dll 2>&1 | tee evidence/11-hosted-nemotron-run.log
# Expect the header line "API key source: NVIDIA_API_KEY -> placeholder only (...)".
