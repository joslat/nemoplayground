# MafDemo: Microsoft Agent Framework agent for an NVIDIA OpenShell sandbox.
# Build with the engine your local OpenShell gateway uses (no registry needed for a Docker-backed gateway):
#   docker build -t maf-demo:1.0 src/MafDemo
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY MafDemo.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/runtime:10.0
# The default OpenShell filesystem policy is read-only for /bin /usr /lib /etc (+ /proc, /var/log),
# read-write for /tmp and the working directory, and denies everything else. A first build that used
# /app failed with EACCES on MafDemo.runtimeconfig.json, so the app lives under /usr instead of
# widening the policy.
COPY --from=build /app /usr/local/lib/mafdemo
# OpenShell runs the workload as the image's non-root user and requires a working directory that user
# can use ("OCI WorkingDir is not usable by the sandbox identity" otherwise). `openshell sandbox download`
# only accepts paths inside the working directory, so traces and eval results go to /workspace/out.
# The .NET runtime images ship a non-root `app` user (UID 1654).
RUN mkdir -p /workspace/out && chown -R app:app /workspace
USER app
WORKDIR /workspace
# No API key here, ever. OpenShell providers inject placeholders at runtime.
ENV OUT_DIR=/workspace/out \
    DOTNET_CLI_TELEMETRY_OPTOUT=1
ENTRYPOINT ["dotnet", "/usr/local/lib/mafdemo/MafDemo.dll"]
