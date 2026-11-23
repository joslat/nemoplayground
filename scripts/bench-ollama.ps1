# Measures local Nemotron throughput through Ollama's native API (eval_count / eval_duration).
# Usage: powershell -File scripts/bench-ollama.ps1 [-Model nemotron-3-nano:4b] [-Runs 3]
param(
  [string]$Model = 'nemotron-3-nano:4b',
  [int]$Runs = 3,
  [string]$Out = "$PSScriptRoot\..\evidence\local-inference-benchmark.json"
)
$ErrorActionPreference = 'Stop'
$prompt = 'In five bullet points, explain why an AI agent should run inside a sandbox with an out-of-process policy engine.'
$results = @()
for ($i = 1; $i -le $Runs; $i++) {
  $body = @{ model = $Model; prompt = $prompt; stream = $false; options = @{ temperature = 0.2; num_predict = 512 } } | ConvertTo-Json -Depth 4
  $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/generate' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 600
  $gpu = (& nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits).Split(',') | ForEach-Object { [int]$_.Trim() }
  $results += [pscustomobject]@{
    run                  = $i
    load_ms              = [math]::Round($r.load_duration / 1e6)
    prompt_tokens        = $r.prompt_eval_count
    prompt_tokens_per_s  = if ($r.prompt_eval_duration) { [math]::Round($r.prompt_eval_count / ($r.prompt_eval_duration / 1e9), 1) } else { $null }
    output_tokens        = $r.eval_count
    output_tokens_per_s  = [math]::Round($r.eval_count / ($r.eval_duration / 1e9), 1)
    gpu_mem_used_mib     = $gpu[0]
    gpu_mem_total_mib    = $gpu[1]
  }
}
$ps = (Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/ps').models | Select-Object name, size, size_vram
$report = [pscustomobject]@{
  model          = $Model
  ollama_version = (Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version').version
  gpu            = (& nvidia-smi --query-gpu=name,driver_version --format=csv,noheader)
  loaded         = $ps
  measured_at    = (Get-Date).ToString('o')
  runs           = $results
}
$report | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 $Out
$report | ConvertTo-Json -Depth 5
