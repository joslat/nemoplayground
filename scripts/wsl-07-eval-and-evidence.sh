#!/usr/bin/env bash
# Run AFTER your rule decisions. Runs the AgentEval checks inside the sandbox and collects the evidence:
# results JSON + OpenTelemetry traces (downloaded from the sandbox), full policy dump, rule history, OCSF denials.
set -uo pipefail
cd "$(dirname "$0")/.."
SB=maf-demo
RUNS="${1:-10}"
OUT=evidence/sandbox-run
mkdir -p "$OUT"

echo "\$ openshell sandbox exec -n $SB -- env OUT_DIR=/workspace/out HARNESS=v2 dotnet /usr/local/lib/mafdemo/MafDemo.dll eval $RUNS"
openshell sandbox exec -n "$SB" --no-tty -- env OUT_DIR=/workspace/out HARNESS=v2 MAFDEMO_LOCATION="OpenShell sandbox $SB" \
  dotnet /usr/local/lib/mafdemo/MafDemo.dll eval "$RUNS" 2>&1 | tee "$OUT/eval-console.log"

echo "\$ openshell sandbox download $SB /workspace/out $OUT"
openshell sandbox download "$SB" /workspace/out "$OUT"

openshell policy get "$SB" --full > evidence/08-policy-final-full.txt 2>&1
openshell rule history "$SB"       > evidence/09-rule-history.txt 2>&1
openshell rule get "$SB"           > evidence/09-rules-all.txt 2>&1
openshell logs "$SB" -n 2000 --source all 2>&1 | grep -E 'OCSF|DENIED|propos' > evidence/10-ocsf-events.log
echo "Evidence written under evidence/ (sandbox-run/, 08-*, 09-*, 10-*)."
ls -la "$OUT"
