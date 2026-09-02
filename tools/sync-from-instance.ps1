param(
    [string]$Instance = "$env:APPDATA\PrismLauncher\instances\Mods(BG and Friends)",
    [string]$Pack     = "$PSScriptRoot\.."
)
$ErrorActionPreference = 'Stop'
Write-Host "== Re-importing mods from instance ==" -ForegroundColor Cyan
# stale metadata is removed first so deleted mods drop out of the pack
Get-ChildItem -LiteralPath (Join-Path $Pack 'mods') -Filter *.pw.toml -File | Remove-Item -Force
& "$PSScriptRoot\import-from-instance.ps1" -Instance $Instance -Pack $Pack
if ($LASTEXITCODE -ne 0) { throw "import failed" }
# every mod ships to every player: singleplayer runs an integrated server
Get-ChildItem -LiteralPath (Join-Path $Pack 'mods') -Filter *.pw.toml -File | ForEach-Object {
    $t = [IO.File]::ReadAllText($_.FullName) -replace '(?m)^side = "(client|server)"$','side = "both"'
    [IO.File]::WriteAllText($_.FullName, $t)
}
Write-Host "== Refreshing managed configs ==" -ForegroundColor Cyan
$n = 0
foreach ($rel in (Get-Content "$PSScriptRoot\managed-configs.txt" | Where-Object { $_ -and $_ -notmatch '^\s*#' })) {
    $src = Join-Path $Instance "minecraft\$rel"
    $dst = Join-Path $Pack $rel
    if (Test-Path -LiteralPath $src) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Force; $n++
    } else { Write-Host "  (skipped, not present) $rel" -ForegroundColor DarkYellow }
}
Write-Host "  $n managed configs refreshed"
& "$Pack\tools\bin\packwiz.exe" --pack-file "$Pack\pack.toml" refresh
Write-Host "Sync complete. Run publish.bat to push to your friends." -ForegroundColor Green
