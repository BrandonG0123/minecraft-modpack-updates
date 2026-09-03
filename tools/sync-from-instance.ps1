<#  Builds BOTH packs from the one Prism instance.

      base (repo root)  - 107 mods, shared configs, server, light shaders,
                          small mod-support resource packs
      plus (plus/)      - identical mods+configs, plus the heavy shaders,
                          full texture packs and Tyler's personal configs

    Mods and shared configs are generated once and copied into plus/, so there
    is only ever one source of truth: the Prism instance.
#>
param(
    [string]$Instance = "$env:APPDATA\PrismLauncher\instances\Mods(BG and Friends)",
    [string]$Pack     = "$PSScriptRoot\.."
)
$ErrorActionPreference = 'Stop'
$plus   = Join-Path $Pack 'plus'
$packwiz = Join-Path $Pack 'tools\bin\packwiz.exe'

# ---------- 1. mods, from the instance ----------
Write-Host "== Importing mods from instance ==" -ForegroundColor Cyan
Get-ChildItem -LiteralPath (Join-Path $Pack 'mods') -Filter *.pw.toml -File -ErrorAction SilentlyContinue | Remove-Item -Force
& "$PSScriptRoot\import-from-instance.ps1" -Instance $Instance -Pack $Pack
# every mod ships to every player: singleplayer runs an integrated server
Get-ChildItem -LiteralPath (Join-Path $Pack 'mods') -Filter *.pw.toml -File | ForEach-Object {
    $t = [IO.File]::ReadAllText($_.FullName) -replace '(?m)^side = "(client|server)"$','side = "both"'
    [IO.File]::WriteAllText($_.FullName, $t)
}

# ---------- 2. shared configs ----------
Write-Host "== Shared configs ==" -ForegroundColor Cyan
$n = 0
foreach ($rel in (Get-Content "$PSScriptRoot\managed-configs.txt" | Where-Object { $_ -and $_ -notmatch '^\s*#' })) {
    # '!' marks a pack-owned file: shipped, but never re-copied from the instance
    if ($rel.StartsWith('!')) { Write-Host ("  (pack-owned, kept) " + $rel.Substring(1)) -ForegroundColor DarkCyan; continue }
    $src = Join-Path $Instance "minecraft\$rel"
    $dst = Join-Path $Pack $rel
    if (Test-Path -LiteralPath $src) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Force; $n++
    } else { Write-Host "  (absent, skipped) $rel" -ForegroundColor DarkYellow }
}
Write-Host "  $n shared configs"

# ---------- 3. mirror mods + configs into plus ----------
Write-Host "== Mirroring into plus/ ==" -ForegroundColor Cyan
foreach ($d in 'mods','config') {
    $target = Join-Path $plus $d
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Recurse -Force (Join-Path $Pack $d) $target
}
Copy-Item -Force (Join-Path $Pack 'servers.dat') (Join-Path $plus 'servers.dat')
Copy-Item -Force (Join-Path $Pack 'pack.toml')   (Join-Path $plus 'pack.toml.tmp') -ErrorAction SilentlyContinue
Remove-Item (Join-Path $plus 'pack.toml.tmp') -ErrorAction SilentlyContinue
Write-Host "  mods + config + servers.dat mirrored"

# ---------- 4. plus-only personal configs ----------
$n = 0
foreach ($rel in (Get-Content "$PSScriptRoot\plus-configs.txt" | Where-Object { $_ -and $_ -notmatch '^\s*#' })) {
    $src = Join-Path $Instance "minecraft\$rel"
    $dst = Join-Path $plus $rel
    if (Test-Path -LiteralPath $src) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Force; $n++
    } else { Write-Host "  (absent, skipped) $rel" -ForegroundColor DarkYellow }
}
Write-Host "  $n personal configs into plus/"

# ---------- 5. shaders + resource packs ----------
Write-Host "== Base assets ==" -ForegroundColor Cyan
foreach ($d in 'shaderpacks','resourcepacks') {
    $t = Join-Path $Pack $d; if (Test-Path $t) { Remove-Item -Recurse -Force $t }
}
& "$PSScriptRoot\import-assets.ps1" -ListFile "$PSScriptRoot\base-assets.txt" -Pack $Pack -Instance $Instance
Write-Host "== Plus assets ==" -ForegroundColor Cyan
foreach ($d in 'shaderpacks','resourcepacks') {
    $t = Join-Path $plus $d; if (Test-Path $t) { Remove-Item -Recurse -Force $t }
}
& "$PSScriptRoot\import-assets.ps1" -ListFile "$PSScriptRoot\plus-assets.txt" -Pack $plus -Instance $Instance

# ---------- 6. refresh both indexes ----------
Write-Host "== Refreshing indexes ==" -ForegroundColor Cyan
& $packwiz --pack-file (Join-Path $Pack 'pack.toml') refresh
& $packwiz --pack-file (Join-Path $plus 'pack.toml') refresh
Write-Host "Sync complete. Run publish.bat to push both packs." -ForegroundColor Green
