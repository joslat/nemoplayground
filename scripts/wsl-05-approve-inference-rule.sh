#!/usr/bin/env bash
# Rule 1 decision, approved by the repo owner on 2026-11-23:
# allow /usr/share/dotnet/dotnet -> host.openshell.internal:11434 (local Nemotron via Ollama) in sandbox maf-demo.
set -uo pipefail
cd "$(dirname "$0")/.."
SB=maf-demo
CHUNK="${1:-f3909e16-b901-48c4-9519-e47eeae45042}"
{
  echo "# $(date -Is) decision by repo owner: APPROVE $CHUNK"
  echo "\$ openshell rule approve $SB --chunk-id $CHUNK"
  openshell rule approve "$SB" --chunk-id "$CHUNK"
  sleep 3
  echo; echo "\$ openshell rule get $SB"
  openshell rule get "$SB"
  echo; echo "\$ openshell policy get $SB --full"
  openshell policy get "$SB" --full
} 2>&1 | tee evidence/05-rule1-approved.log
