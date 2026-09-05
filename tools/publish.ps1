param([string]$Pack = "$PSScriptRoot\..", [string]$Message)
$ErrorActionPreference = 'Stop'
Set-Location $Pack
$packwiz = "$Pack\tools\bin\packwiz.exe"

& $packwiz --pack-file "$Pack\pack.toml" refresh
Push-Location "$Pack\plus"; & $packwiz refresh; Pop-Location
Push-Location "$Pack\modsonly"; & $packwiz refresh; Pop-Location

& "$PSScriptRoot\guard-personal-data.ps1" -Pack $Pack -Mode base
if ($LASTEXITCODE -ne 0) { exit 1 }
& "$PSScriptRoot\guard-personal-data.ps1" -Pack "$Pack\plus" -Mode plus
if ($LASTEXITCODE -ne 0) { exit 1 }
& "$PSScriptRoot\guard-personal-data.ps1" -Pack "$Pack\modsonly" -Mode modsonly
if ($LASTEXITCODE -ne 0) { exit 1 }

# rebuild both friend zips so instance.cfg always matches the live pack URLs
& "$PSScriptRoot\make-friend-zip.ps1"
if ($LASTEXITCODE -ne 0) { Write-Host "base zip failed" -ForegroundColor Red; exit 1 }
& "$PSScriptRoot\make-friend-zip.ps1" -Variant plus
if ($LASTEXITCODE -ne 0) { Write-Host "plus zip failed" -ForegroundColor Red; exit 1 }

if (-not $Message) { $Message = "Update pack - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }

# Windows PowerShell turns native stderr into an ErrorRecord, and git writes
# ordinary progress to stderr. Trust $LASTEXITCODE instead.
$ErrorActionPreference = 'Continue'
git add -A 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "git add failed" -ForegroundColor Red; exit 1 }
$staged = @(git diff --cached --name-only 2>$null)
if (-not $staged -or $staged.Count -eq 0) { Write-Host "Nothing changed - nothing to publish." -ForegroundColor Yellow; exit 0 }
Write-Host "Publishing $($staged.Count) changed file(s)" -ForegroundColor Cyan
$staged | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }
if ($staged.Count -gt 15) { Write-Host "  ... and $($staged.Count - 15) more" }
# Pass the message through a file: quotes and colons in a -m argument get
# mangled by PowerShell/git argument parsing and abort the commit.
$msgFile = Join-Path $env:TEMP "packwiz-commit-msg.txt"
[IO.File]::WriteAllText($msgFile, $Message)
git commit -q -F $msgFile 2>&1 | ForEach-Object { Write-Host "  $_" }
Remove-Item $msgFile -Force -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0) { Write-Host "git commit failed" -ForegroundColor Red; exit 1 }
git push origin main 2>&1 | ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) { Write-Host "git push FAILED - nothing reached your friends." -ForegroundColor Red; exit 1 }
Write-Host ""
Write-Host "Published both packs. Friends get it next launch." -ForegroundColor Green
