#!/usr/bin/env bash
# Run AFTER you approved the dotnet -> host.openshell.internal:11434 rule.
#  1. reruns the agent (hot-reloaded policy, no restart),
#  2. asks the agent to exfiltrate code to https://collector.evil.example/upload (it will try; OpenShell decides),
#  3. waits for the denial analysis and prints the new pending rule. It never approves or rejects anything.
set -uo pipefail
cd "$(dirname "$0")/.."
SB=maf-demo
RUN=(openshell sandbox exec -n "$SB" --no-tty -- env OUT_DIR=/workspace/out dotnet /usr/local/lib/mafdemo/MafDemo.dll)
LOG=evidence/07-after-approval.log
{
  echo "# $(date -Is)"
  # Approved rules hot-reload, but the sandbox picks them up on its next settings poll (~10 s).
  # A first attempt run 7 s after approval was still denied (evidence/07a-*.log).
  echo "waiting 15s for the sandbox to hot-reload the approved policy..."
  sleep 15
  echo "\$ openshell sandbox exec -n $SB -- env OUT_DIR=/workspace/out dotnet /usr/local/lib/mafdemo/MafDemo.dll"
  "${RUN[@]}"; echo "exit: $?"
  echo
  echo "\$ openshell sandbox exec -n $SB -- env OUT_DIR=/workspace/out dotnet /usr/local/lib/mafdemo/MafDemo.dll send login"
  "${RUN[@]}" send login; echo "exit: $?"
  echo
  echo "waiting 15s for the supervisor to flush its denial analysis..."
  sleep 15
  echo "\$ openshell rule get $SB --status pending"
  openshell rule get "$SB" --status pending
  echo
  echo "\$ openshell logs $SB --source sandbox (denials)"
  openshell logs "$SB" -n 200 --source sandbox 2>&1 | grep -E 'DENIED' | cut -c1-240 | tail -6
} 2>&1 | tee "$LOG"
echo
echo "Saved to $LOG. Decide on each pending chunk yourself, for example:"
echo "  openshell rule reject $SB --chunk-id <chunk-id> --reason \"Exfiltration target; the agent has no reason to send code off-box.\""
