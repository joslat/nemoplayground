#!/usr/bin/env bash
# Step 4b: long-lived sandbox for the MAF agent so rules can be reviewed and hot-reloaded.
#   bash scripts/wsl-04-maf-governed.sh create   # sandbox + first (denied) run + pending rules
#   bash scripts/wsl-04-maf-governed.sh run [args] # run the agent again (e.g. "demo", "send login", "eval 10")
#   bash scripts/wsl-04-maf-governed.sh rules      # show pending rules
set -uo pipefail
cd "$(dirname "$0")/.."
SB=maf-demo
APP=/usr/local/lib/mafdemo/MafDemo.dll

case "${1:-create}" in
  create)
    openshell sandbox delete "$SB" >/dev/null 2>&1 || true
    sleep 2
    echo "\$ openshell sandbox create --name $SB --from maf-demo:1.0 --provider ollama --detach -- sleep infinity"
    openshell sandbox create --name "$SB" --from maf-demo:1.0 --provider ollama --detach --no-tty -- sleep infinity
    for i in $(seq 1 30); do openshell sandbox list 2>/dev/null | grep -q "^$SB .*Ready" && break; sleep 1; done
    openshell sandbox list
    echo; echo "\$ openshell sandbox exec -n $SB -- dotnet $APP"
    openshell sandbox exec -n "$SB" --no-tty -- env OUT_DIR=/workspace/out dotnet "$APP"
    echo "exit: $?"
    sleep 15   # the supervisor flushes its denial analysis ~10s after the denial
    echo; echo "\$ openshell rule get $SB --status pending"
    openshell rule get "$SB" --status pending
    ;;
  run)
    shift
    echo "\$ openshell sandbox exec -n $SB -- dotnet $APP $*"
    openshell sandbox exec -n "$SB" --no-tty -- env OUT_DIR=/workspace/out dotnet "$APP" "$@"
    echo "exit: $?"
    ;;
  rules)
    echo "\$ openshell rule get $SB --status pending"
    openshell rule get "$SB" --status pending
    ;;
esac
