param([string]$Pack = "$PSScriptRoot\..", [string]$Message)
$ErrorActionPreference = 'Stop'
Set-Location $Pack

& "$Pack\tools\bin\packwiz.exe" refresh

# refuse to push if anything player-personal ended up in the pack
& "$PSScriptRoot\guard-personal-data.ps1" -Pack $Pack
if ($LASTEXITCODE -ne 0) { exit 1 }

if (-not $Message) { $Message = "Update pack - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }

# Windows PowerShell turns any native stderr output into an ErrorRecord, and git
# writes ordinary progress to stderr. Drop to Continue and trust $LASTEXITCODE,
# which is the real success signal for a native exe.
$ErrorActionPreference = 'Continue'

git add -A 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "git add failed" -ForegroundColor Red; exit 1 }

$staged = @(git diff --cached --name-only 2>$null)
if (-not $staged -or $staged.Count -eq 0) {
    Write-Host "Nothing changed - nothing to publish." -ForegroundColor Yellow
    exit 0
}
Write-Host "Publishing $($staged.Count) changed file(s):" -ForegroundColor Cyan
$staged | Select-Object -First 25 | ForEach-Object { Write-Host "  $_" }
if ($staged.Count -gt 25) { Write-Host "  ... and $($staged.Count - 25) more" }

git commit -q -m $Message 2>&1 | ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) { Write-Host "git commit failed" -ForegroundColor Red; exit 1 }

git push origin main 2>&1 | ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) { Write-Host "git push FAILED - nothing reached your friends." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Published. Friends get it next time they hit Launch." -ForegroundColor Green
Write-Host "GitHub Pages takes ~30-60s to serve the new files." -ForegroundColor DarkGray
