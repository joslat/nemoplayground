#!/usr/bin/env bash
# Rule 2 decision (2026-11-23, under the repo owner's instruction to decide what makes sense):
# reject allow_collector_evil_example_443, proposed after the agent tried to post source code off-box.
set -uo pipefail
cd "$(dirname "$0")/.."
SB=maf-demo
CHUNK="${1:-dd043e2f-b977-4df9-9a0b-eb7565740a96}"
REASON="Exfiltration target from an injected instruction; the agent has no reason to send source code off-box."
{
  echo "# $(date -Is) decision: REJECT $CHUNK"
  echo "\$ openshell rule reject $SB --chunk-id $CHUNK --reason \"$REASON\""
  openshell rule reject "$SB" --chunk-id "$CHUNK" --reason "$REASON"
  sleep 2
  echo; echo "\$ openshell rule get $SB"
  openshell rule get "$SB"
  echo; echo "\$ openshell rule history $SB"
  openshell rule history "$SB"
} 2>&1 | tee evidence/07b-rule2-rejected.log
