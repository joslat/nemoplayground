#!/usr/bin/env bash
# Step 3: expose host Ollama to sandboxes through a credentialless provider profile, then smoke-test it.
# Run from the repo root inside WSL:  bash scripts/wsl-01-ollama-provider.sh
set -uo pipefail
cd "$(dirname "$0")/.."

if ! openshell profile describe ollama-openai >/dev/null 2>&1; then
  echo '$ openshell profile lint -f openshell/profiles/ollama-openai.yaml'
  openshell profile lint -f openshell/profiles/ollama-openai.yaml
  echo '$ openshell profile import -f openshell/profiles/ollama-openai.yaml'
  openshell profile import -f openshell/profiles/ollama-openai.yaml
fi
if ! openshell provider get ollama >/dev/null 2>&1; then
  echo '$ openshell provider create --name ollama --type ollama-openai'
  openshell provider create --name ollama --type ollama-openai
fi
echo '$ openshell provider list'
openshell provider list

echo
echo '$ openshell sandbox create --name ollama-smoke --from curlimages/curl:8.11.1 --provider ollama --no-keep -- curl -sS http://host.openshell.internal:11434/v1/models'
openshell sandbox create --name ollama-smoke --from curlimages/curl:8.11.1 --provider ollama --no-keep --no-tty \
  -- curl -sS -m 20 http://host.openshell.internal:11434/v1/models
echo "exit: $?"
