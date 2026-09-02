param([string]$Pack = "$PSScriptRoot\..", [string]$Message)
$ErrorActionPreference = 'Stop'
Set-Location $Pack
& "$Pack\tools\bin\packwiz.exe" refresh

# refuse to push if anything player-personal ended up in the pack
& "$PSScriptRoot\guard-personal-data.ps1" -Pack $Pack
if ($LASTEXITCODE -ne 0) { exit 1 }

if (-not $Message) { $Message = "Update pack - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
git add -A
$staged = git diff --cached --name-only
if (-not $staged) { Write-Host "Nothing changed - nothing to publish." -ForegroundColor Yellow; exit 0 }
Write-Host "Publishing $($staged.Count) changed file(s):" -ForegroundColor Cyan
$staged | Select-Object -First 25 | ForEach-Object { Write-Host "  $_" }
git commit -q -m $Message
git push origin main
Write-Host ""
Write-Host "Published. Friends get it next time they hit Launch." -ForegroundColor Green
