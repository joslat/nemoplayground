# TASK: Nemotron inside an OpenShell sandbox, plus a governed MAF agent

Revised 2026-11-23 against OpenShell v0.1.9 docs and this machine. Changes from the original brief are marked **(changed)**.

## Goal
Produce a working, documented demo: (1) an agent running inside an
NVIDIA OpenShell sandbox using a Nemotron model, and (2) a Microsoft Agent Framework (.NET)
agent running in OpenShell that reaches Nemotron only through an OpenShell provider.
**(changed)** OpenShell v0.1.9 removed `openshell inference set` and the `https://inference.local/v1`
managed route ("Code that still calls the retired managed virtual endpoint fails DNS resolution").
The agent now calls the provider's native endpoint (`http://host.openshell.internal:11434/v1` for
local Ollama, `https://integrate.api.nvidia.com/v1` for hosted Nemotron) with a placeholder key; the
gateway proxy enforces the provider profile and injects the real credential at egress.

## Constraints
- Follow NVIDIA docs exactly: https://docs.nvidia.com/openshell/latest/ and
  https://docs.nvidia.com/nemoclaw/ . If a command fails, read the current docs page before improvising.
- Never put real API keys in code, images or logs. Use env vars and OpenShell providers.
- Do not approve OpenShell rules automatically. Stop and show me each pending rule.
- Platform: Windows 10 Pro 22H2 (19045) + WSL 2.6.3 (kernel 6.6.87, Landlock on) + Ubuntu 24.04 +
  Docker Desktop 29.1.3 (OpenShell support matrix: **Experimental**).
- GPU/memory: RTX 3070 8 GB VRAM, 32 GB RAM (Docker VM capped at 16 GB).

## Steps
1. Install OpenShell CLI + gateway (install.sh). Verify with `openshell status`.
   **(changed)** On WSL 2 + Docker Desktop, set `[openshell.drivers.docker] supervisor_network_mode = "bridge"`
   in `~/.config/openshell/gateway.toml`, or sandboxes fail with "Startup configuration fetch failed".
2. Route A: OpenRouter provider + OpenCode sandbox on openrouter/nvidia/nemotron-3.5-lightning:free.
   Trigger one network denial, show the pending rule, wait for a decision. (Needs an OpenRouter key.)
3. Local model: Ollama **0.40.x** (0.6.0 is too old) with `nemotron-3-nano:4b` (2.8 GB, fits the 8 GB GPU).
   Expose it via the credentialless `ollama-openai` profile (host.openshell.internal:11434).
   **(changed)** Ollama can stay bound to 127.0.0.1: Docker Desktop's host-gateway reaches it.
4. .NET agent: MAF + Microsoft.Extensions.AI, OPENAI_BASE_URL/MODEL from env, placeholder key.
   **(changed)** No registry push: `--from` takes a locally built image on a Docker-backed gateway.
   **(changed)** Image must run as a non-root user with a usable WORKDIR, and keep the app under /usr
   (default filesystem policy: read-only /bin /usr /lib /etc, read-write /tmp + workdir).
   **(changed)** Provider profiles have a `binaries` allowlist; dotnet is not in the stock profiles, so the
   first run is denied and OpenShell proposes a rule (the governance moment of the demo).
5. OpenTelemetry tracing to a local JSONL file (downloaded with `openshell sandbox download`).
6. Three AgentEval checks on 10 runs: task success, tool-use fidelity, one prompt-injection probe. JSON.
   **(added)** Compare harness v1 (lookup by CWE id) vs v2 (lookup by weakness name) on the same model.

## Acceptance criteria
- README.md with exact commands used, versions, platform, model, memory and tokens/s.
- evidence/ folder: pending-rule output, approve/reject log, OpenShell policy dump
  (`openshell policy get <name> --full`), trace file, AgentEval JSON.
- One paragraph: what OpenShell blocked, what I approved, and why.
