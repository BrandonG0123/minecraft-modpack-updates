$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$H = @{ 'User-Agent' = 'packwiz-updater' }
Write-Host "Finding the latest successful packwiz build..." -ForegroundColor Cyan
$runs = Invoke-RestMethod -Headers $H `
    'https://api.github.com/repos/packwiz/packwiz/actions/workflows/go.yml/runs?branch=main&status=success&per_page=1'
$run = $runs.workflow_runs[0]
Write-Host "  run #$($run.run_number)  $($run.created_at)"
$url = "https://nightly.link/packwiz/packwiz/actions/runs/$($run.id)/Windows%2064-bit.zip"
$zip = Join-Path $env:TEMP 'packwiz-dl.zip'
Invoke-WebRequest -Headers $H -Uri $url -OutFile $zip
$bin = Join-Path $PSScriptRoot 'bin'
New-Item -ItemType Directory -Force -Path $bin | Out-Null
Expand-Archive -Path $zip -DestinationPath $bin -Force
Remove-Item $zip -Force
& "$bin\packwiz.exe" --help | Select-Object -First 1
Write-Host "packwiz updated." -ForegroundColor Green
