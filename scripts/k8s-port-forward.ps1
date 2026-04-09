param(
  [int]$LocalPort = 8000,
  [string]$Address = "0.0.0.0",
  [string]$Namespace = "default"
)

$ErrorActionPreference = "Stop"

while ($true) {
  Write-Host "Starting port-forward: http://${Address}:${LocalPort} -> svc/latexocr:${Namespace} (port 8000)" -ForegroundColor Cyan
  try {
    kubectl -n $Namespace port-forward --address $Address svc/latexocr "${LocalPort}:8000" --pod-running-timeout=2m
  }
  catch {
    Write-Warning $_
  }

  Write-Warning "port-forward stopped. Restarting in 2 seconds... (Ctrl+C to stop)"
  Start-Sleep -Seconds 2
}
