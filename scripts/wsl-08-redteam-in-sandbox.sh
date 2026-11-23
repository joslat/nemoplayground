#!/usr/bin/env bash
# Upgrade test (AgentEval 1.0.0-rc.3, MAF 1.27, MEAI 11) inside the existing maf-demo sandbox, keeping its
# approved policy: upload the new build into the workspace, run a light AgentEval red-team scan, then the
# 10-run eval, and download the results. Never approves or rejects rules; it only prints pending ones.
#   bash scripts/wsl-08-redteam-in-sandbox.sh /mnt/c/path/to/publish [probesPerAttack] [evalRuns]
set -uo pipefail
cd "$(dirname "$0")/.."
SB=maf-demo
SRC="${1:?path to the dotnet publish output}"
PROBES="${2:-3}"
RUNS="${3:-10}"
OUT=evidence/sandbox-run-rc3
mkdir -p "$OUT"
APP="/workspace/app/$(basename "$SRC")/MafDemo.dll"   # upload into an existing dir keeps the source folder name
ENVV=(env OUT_DIR=/workspace/out-rc3 HARNESS=v2 MAFDEMO_LOCATION="OpenShell sandbox $SB")
{
  echo "# $(date -Is)"
  if [ "${SKIP_UPLOAD:-0}" != "1" ]; then
    echo "\$ openshell sandbox upload $SB <publish> /workspace/app --no-git-ignore"
    openshell sandbox upload "$SB" "$SRC" /workspace/app --no-git-ignore
    sleep 5   # a run started right after an overwrite once saw an empty runtimeconfig.json
  fi
  echo
  echo "\$ openshell sandbox exec -n $SB -- dotnet $APP redteam $PROBES"
  openshell sandbox exec -n "$SB" --no-tty -- "${ENVV[@]}" dotnet "$APP" redteam "$PROBES"
  echo "exit: $?"
  echo
  echo "\$ openshell sandbox exec -n $SB -- dotnet $APP eval $RUNS"
  openshell sandbox exec -n "$SB" --no-tty -- "${ENVV[@]}" dotnet "$APP" eval "$RUNS"
  echo "exit: $?"
  sleep 15
  echo
  echo "\$ openshell rule get $SB --status pending"
  openshell rule get "$SB" --status pending
} 2>&1 | tee "$OUT/console.log"
openshell sandbox download "$SB" /workspace/out-rc3 "$OUT"
openshell logs "$SB" -n 3000 --source sandbox 2>&1 | grep -E 'DENIED' | tail -50 > "$OUT/ocsf-denials.log"
ls -la "$OUT"
