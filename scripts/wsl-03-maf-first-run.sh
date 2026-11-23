#!/usr/bin/env bash
# Step 4a: run the .NET MAF agent in OpenShell with the stock (docs) ollama provider.
# Expected: the provider profile only lists curl/python binaries, so dotnet's call to the model
# endpoint is denied and OpenShell proposes a network rule. Rules are NOT auto-approved here.
set -uo pipefail
cd "$(dirname "$0")/.."
openshell sandbox delete maf-demo >/dev/null 2>&1 || true
sleep 2

echo '$ openshell sandbox create --name maf-demo --from maf-demo:1.0 --provider ollama -- dotnet /usr/local/lib/mafdemo/MafDemo.dll'
openshell sandbox create --name maf-demo --from maf-demo:1.0 --provider ollama --no-tty -- dotnet /usr/local/lib/mafdemo/MafDemo.dll
echo "exit: $?"
sleep 5

echo; echo '$ openshell sandbox list'
openshell sandbox list
echo; echo '$ openshell rule get maf-demo --status pending'
openshell rule get maf-demo --status pending
echo; echo '$ openshell logs maf-demo -n 60 --source sandbox --level info'
openshell logs maf-demo -n 60 --source sandbox --level info 2>&1 | grep -iE 'deny|denied|block|proposal|rule|policy|dotnet|11434|egress' | cut -c1-300 | tail -25
