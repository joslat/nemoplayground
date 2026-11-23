# Runs the AgentEval checks on the Windows host (NOT inside OpenShell) against local Ollama,
# for both harness versions, so v1 vs v2 can be compared with the same model.
# Usage: powershell -File scripts/host-eval.ps1 [-Runs 10]
param([int]$Runs = 10, [string]$OutName = 'agenteval-host')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root "evidence\$OutName"
New-Item -ItemType Directory -Force $out | Out-Null
$env:OPENAI_BASE_URL = 'http://127.0.0.1:11434/v1'
$env:MODEL = 'nemotron-3-nano:4b'
$env:OUT_DIR = $out
Push-Location (Join-Path $root 'src\MafDemo')
try {
  dotnet build -c Release | Out-Null
  foreach ($h in 'v1', 'v2') {
    $env:HARNESS = $h
    "===== HARNESS=$h ====="
    dotnet run -c Release --no-build -- eval $Runs
  }
} finally { Pop-Location }
